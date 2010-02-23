module Monque
  class Job
    attr_accessor :record, :queue
    
    def initialize(queue, record)
      @queue = queue
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
    
    def lock
      update_attributes "$set" => {:in_progress => true}
    end
    
    def unlock
      update_attributes "$set" => {:in_progress => false}
    end
    
    def remove
      @queue.remove({:_id => @record["_id"]})
    end
    
    def perform
      result = payload_class.perform(*args)
      remove
      result
    rescue => e
      fail(e)
    end
    
    private
    def update_attributes(attributes)
      @queue.update({:_id => @record["_id"]}, attributes)
    end
    
    def fail(exception)
      fail_text = "#{exception.message}\n#{exception.backtrace.join("\n")}"
      update_attributes "$set" => {:in_progress => false, :last_error => fail_text, :run_after => Time.now + 60}, "$inc" => {:attempts => 1}
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