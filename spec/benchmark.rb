# ./spec/benchmark.rb

dir = File.dirname(File.expand_path(__FILE__))
$LOAD_PATH.unshift(File.join(dir, '..', 'lib'))
require 'monque'
require 'benchmark'

class SimpleJob
  def self.perform
    "Done!"
  end
end

class Job1 < SimpleJob
  @queue = :queue1
end

class Job2 < SimpleJob
  @queue = :queue2
end

class Job3 < SimpleJob
  @queue = :queue3
end

class Job4 < SimpleJob
  @queue = :queue4
end

Monque.db = Mongo::Connection.new.db("monque_benchmark")
Monque.drop

class Array
  def rand
    self[Kernel.rand(length)]
  end
end

priorities = [0,1,2,3,4,5,6]

result = Benchmark.measure do
  [Job1, Job2, Job3, Job4, Job3, Job2, Job1].each do |job|
    10_000.times do
      Monque.enqueue(job, :job_options => {:priority => priorities.rand})
    end
  end
end

puts "Enqueuing"
puts result

worker = Monque::Worker.new("queue0", "queue1", "queue2", "queue3")
result = Benchmark.measure { worker.work(0) }

puts "Working"
puts result

# With 7 000 entries
#
# Enqueuing
#   1.480000   0.130000   1.610000 (  1.624354)
# Working
#   4.270000   0.390000   4.660000 (  5.854451)

# With 70 000 entries
#
# Enqueuing
#  14.720000   1.190000  15.910000 ( 15.979726)
# Working
#  35.410000   3.030000  38.440000 ( 59.490516)
