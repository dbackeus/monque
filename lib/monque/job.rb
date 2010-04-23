module Monque
  class Job
    attr_accessor :record, :queue_name
    
    def self.all
      Monque.queues.collect do |queue_name|
        Monque.queue(queue_name).find.collect { |record| Job.new(queue_name, record) }
      end.flatten
    end
    
    def initialize(queue_name, record)
      @queue_name = queue_name
      @record = record
    end
    
    def payload_class
      @payload_class ||= constantize(@record["klass"])
    end
    
    def args
      @record["args"]
    end
    
    def priority
      @record["priority"]
    end
    
    def last_error
      @record["last_error"]
    end
    
    def attempts
      @record["attempts"] || 0
    end
    
    def run_after
      @record["run_after"]
    end
    
    def in_progress?
      @record["in_progress"]
    end
    
    def lock
      update_attributes "$set" => {"in_progress" => true}
    end
    
    def unlock
      update_attributes "$set" => {"in_progress" => false}
    end
    
    def destroy
      queue.remove({"_id" => @record["_id"]})
    end
    
    def perform
      payload_class.perform(*args)
      destroy
    rescue => e
      fail(e)
    end
    
    private
    def queue
      Monque.queue(queue_name)
    end
    
    def update_attributes(attributes)
      @record.merge!(attributes["$set"])
      queue.update({"_id" => @record["_id"]}, attributes)
    end
    
    def fail(exception)
      fail_text = "#{exception.message}\n#{exception.backtrace.join("\n")}"
      Monque.logger.error "Failed Job #{self.inspect}"
      Monque.logger.error fail_text
      update_attributes "$set" => {"in_progress" => false, "last_error" => fail_text, "run_after" => Time.now + 60}, "$inc" => {"attempts" => 1}
      false
    end
    
    def constantize(camel_cased_word)
      names = camel_cased_word.split('::')
      names.shift if names.empty? || names.first.empty?

      constant = Object
      names.each do |name|
        constant = constant.const_get(name) || constant.const_missing(name)
      end
      constant
    end
  end
end
