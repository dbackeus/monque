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
    
    def lock
      @queue.update({:_id => @record["_id"]}, "$set" => {"in_progress" => true})
    end
    
    def unlock
      @queue.update({:_id => @record["_id"]}, "$set" => {"in_progress" => false})
    end
    
    def remove
      @queue.remove({:_id => @record["_id"]})
    end
    
    private
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