module Monque
  class Worker
    def initialize(*queues)
      @queues = queues.empty? ? ["default"] : queues
    end
    
    def work
      @queues.each do |queue|
        while job = Monque.reserve(queue)
          job.perform
        end
      end
    end
  end
end