dir = File.dirname(File.expand_path(__FILE__))
$LOAD_PATH.unshift(dir)
$LOAD_PATH.unshift(File.join(dir, '..', 'lib'))
require 'rubygems'
require 'monque'
require 'spec'
require 'spec/autorun'

Monque.logger = Logger.new(nil)

if !system("which mongod")
  puts '', "** can't find `mongod` in your path"
  abort ''
end

at_exit do
  pid = File.read("#{dir}/db/mongod.lock")
  `rm -f #{dir}/db/mongod.lock`
  `rm -f #{dir}/db/monque_test*`
  `rm -rf #{dir}/db/_tmp`
  puts "Killing test mongodb server..."
  Process.kill("KILL", pid.chomp.to_i)
end

puts "Starting mongod for testing at localhost:26000..."
`mongod run --fork --nohttpinterface --config #{dir}/db/mongodb-test.conf`

loop do
  begin
    Monque.db = Mongo::Connection.new("localhost", 26000).db("monque_test")
    break
  rescue Mongo::ConnectionFailure
    sleep 0.1 # Wait for mongo to be ready
  end
end  

Spec::Runner.configure do |config|  
end

class SimpleJob
  def self.perform
    "Done!"
  end
end

class GoodJob
  def self.perform(name, surname)
    "Hello #{name} #{surname}"
  end
end

class GoodSpecificQueueJob < GoodJob
  def self.queue
    "specific"
  end
end

class BadJob
  def self.perform
    raise "epic fail"
  end
end

class JobWithoutPerform
end
