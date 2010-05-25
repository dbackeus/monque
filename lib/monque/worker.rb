module Monque
  class Worker
    # Workers should be initialized with the names of all queues
    # you wish the worker to work on. Note that the queues will
    # be cycled in the same order that you gave them. A queue is
    # worked on until all items in that queue are done. This means
    # setting priority will not matter across different queues.
    # 
    # If no queues are given the worker will work on all availible
    # queues.
    def initialize(*queues)
      @queues = queues unless queues.empty?
    end
    
    # This will start the work loop for the worker. If interval
    # is set to 0 the worker will refrain from looping after the
    # first run.
    #
    # @param [Integer] interval the time to sleep between
    # each loop, defaults to 5
    def work(interval = 5)
      register_signal_handlers
      
      Monque.logger.info "*** Worker #{self} is going to work.\n"
      
      loop do
        break if @shutdown
        queues.each do |queue|
          while job = Monque.reserve(queue)
            Monque.logger.info "\n*** Performing job #{job.inspect}.\n"
            job.perform
            Monque.logger.info "\n*** Performed job #{job.inspect} successfully.\n"
            exit if @shutdown
          end
        end
        break if interval.to_i == 0
        sleep interval.to_i
      end
    end
    
    def shutdown
      Monque.logger.info "\n***Shutting down now or after current job is completed.\n"
      @shutdown = true
    end
    
    private
    def register_signal_handlers
      trap('QUIT') { shutdown }
    end
    
    def queues
      @queues || Monque.queues
    end
  end
end
