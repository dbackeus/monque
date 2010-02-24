module Monque
  class Worker
    def initialize(*queues)
      @queues = queues.empty? ? ["default"] : queues
    end
    
    def work(interval = 5)
      loop do
        @queues.each do |queue|
          while job = Monque.reserve(queue)
            job.perform
          end
        end
        break if interval.to_i == 0
        sleep interval.to_i
      end
    end
  end
end