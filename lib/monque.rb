require 'rubygems'
require 'mongo'
require 'monque/job'
require 'monque/worker'

module Monque
  @queues = {}
  
  def self.db=(database)
    database.strict = true
    @database = database
  end
  
  def self.db
    @database
  end
  
  # This method can be used to conveniently add a job to a queue.
  #
  # Which queue to add the job to is determined like this:
  # 
  # 1) looks for :queue to be set as a job_option
  # 2) looks for a queue method on the provided class
  # 3) defaults to "default"
  #
  # Which priority to use for the job is determined like this:
  #
  # 1) looks for :priority to be set as a job_option
  # 2) defaults to 0
  #
  # @param [Class] klass the class to handle the job, must respond to perform
  # @param [*] args the arguments you want to be passed to the perform method,
  # you can also end the list with a hash of options given the key :job_options.
  #
  # @example
  #  # It's simple
  #  Monque.enqueue(MyJob)
  #  # Arguments!
  #  Monque.enqueue(MyJobWithArguments, "David", 2, :yes_even => "hash_is_ok")
  #  # Job options can be set like this, they will not be added as arguments of the job
  #  Monque.enqueue(AnotherJob, "foo", :this_is => "an_argument", :job_options => {:queue => :thumbnails, :priority => 2})
  #
  # @return [Monque::Job] job the new job it created.
  def self.enqueue(klass, *args)
    options = {}
    if args.last.is_a?(Hash)
      options = args.last.delete(:job_options) || {}
      args.pop if args.last.empty?
    end
    
    queue_name = options[:queue] || queue_from_class(klass) || "default"
    
    record = { "klass" => klass.to_s, 
               "args" => args, 
               "in_progress" => false, 
               "priority" => options[:priority] || 0, 
               "run_after" => Time.now }
    
    id = queue(queue_name).insert(record)
    
    Job.new(queue_name, record.merge("_id" => id))
  end
  
  # This method is used to fetch the mongo collection object for
  # the specified queue.
  # 
  # @param [Symbol, String] queue_name the name of the queue to fetch
  #
  # @return [Mongo::Collection] queue
  def self.queue(queue_name)
    queue_name = "monque_#{queue_name}"
    @queues[queue_name] ||= db.collection(queue_name)
  rescue Mongo::MongoDBError
    queue = db.create_collection(queue_name)
    queue.create_index :in_progress
    queue.create_index :priority
    queue.create_index :run_after
    @queues[queue_name] = queue
  end
  
  # This method is used to fetch a list of all currently populated queues.
  #
  # @return [Array] queues
  def self.queues
    db.collection_names.
      select { |c| c.index("monque_") == 0 }.
      collect { |c| c.split("_")[1..-1].join("_") }
  end
  
  # This method retrieves the highest priorotised job in the specified queue,
  # locks the job so that no one else can reserve it and returns it. If no
  # job is availible nil will be returned.
  #
  # @param [Symbol, String] queue_name 
  #
  # @return [Monque::Job] job
  def self.reserve(queue_name = "default")
    queue = queue(queue_name)
    
    record = queue.find_one({:in_progress => false, :run_after => {"$lt" => Time.now}}, :sort => ["priority", :desc])
    return nil unless record
    
    job = Job.new(queue_name, record)
    job.lock
    job
  end
  
  # This method gets the first job in the specified queue without bothering
  # about any arguments.
  #
  # @param [Symbol, String] queue_name 
  #
  # @return [Monque::Job] job
  def self.first(queue_name = "default")
    queue = queue(queue_name)
    record = queue.find_one
    return nil unless record
    Job.new(queue_name, record)
  end
  
  def self.drop
    @queues = {}
    db.collections.each { |collection| collection.drop if collection.name.index("monque_") == 0 }
  end
  
  private
  def self.queue_from_class(klass)
    klass.instance_variable_get(:@queue) || (klass.respond_to?(:queue) and klass.queue)
  end
end
