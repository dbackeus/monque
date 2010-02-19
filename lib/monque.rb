require 'rubygems'
require 'mongo'
require 'monque/job'

module Monque
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
    
    queue = queue(options[:queue] || queue_from_class(klass) || "default")
    
    record = {"klass" => klass.to_s, "args" => args, "in_progress" => false, "priority" => options[:priority] || 0}
    id = queue.insert(record)
    Job.new(queue, record.merge("_id" => id))
  end
  
  # This method is used to fetch the mongo collection object for
  # the specified queue.
  # 
  # @param [Symbol, String] queue_name the name of the queue to fetch
  #
  # @return [Mongo::Collection] queue
  def self.queue(queue_name)
    db.collection("monque_#{queue_name}")
  rescue Mongo::MongoDBError
    queue = db.create_collection("monque_#{queue_name}")
    queue.create_index :in_progress
    queue.create_index :priority
    queue
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
    
    record = queue.find_one({"in_progress" => false}, :sort => ["priority", :desc])
    return nil unless record
    
    job = Job.new(queue, record)
    job.lock
    job
  end
  
  private
  def self.queue_from_class(klass)
   klass.queue if klass.respond_to?(:queue)
  end
end