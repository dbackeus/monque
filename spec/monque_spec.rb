require 'spec_helper'

describe Monque do
  before(:each) do
    Monque.drop
  end
  
  describe "logger" do
    after(:each) do
      Monque.logger = Logger.new(nil)
    end
    
    it "should be a Logger" do
      Monque.logger.should be_instance_of(Logger)
    end
    
    it "should be at info level" do
      Monque.logger = nil # Reset the logger so that we get the default
      Monque.logger.level.should == Logger::INFO
    end
    
    it "should be assignable" do
      new_logger = Logger.new(STDOUT)
      Monque.logger = new_logger
      Monque.logger.should == new_logger
    end
  end
  
  it "should add a job to the 'default' queue if non specified" do
    Monque.enqueue(GoodJob)
    Monque.queue(:default).size.should == 1
  end
  
  it "should add a job to the specified queue if set in the job class" do
    Monque.enqueue(GoodSpecificQueueJob)
    Monque.queue(:specific).size.should == 1
  end
  
  it "should return a Job when enqueuing" do
    job = Monque.enqueue(GoodJob)
    
    job.should be_instance_of(Monque::Job)
  end
  
  it "should reserve jobs from default queue" do
    Monque.enqueue(GoodJob, "Luke", "Skywalker")
    job = Monque.reserve
    
    job.should be_instance_of(Monque::Job)
    job.payload_class.should == GoodJob
    job.args.should == ["Luke", "Skywalker"]
    
    Monque.reserve.should be_nil
  end
  
  it "should re-queue jobs" do
    Monque.enqueue(GoodJob)
    
    job = Monque.reserve
    job.unlock
    
    expected = job.record
    expected.delete("in_progress")
    
    Monque.reserve.record.values.should include(*expected.values)
  end
  
  it "should reserve jobs from a specific queue" do
    Monque.enqueue(GoodSpecificQueueJob, "James", "Bond")
    Monque.enqueue(GoodSpecificQueueJob, "James", "Bond")
    
    Monque.reserve.should be_nil

    job = Monque.reserve(:specific)
    job.payload_class.should == GoodSpecificQueueJob
    job.args.should == ["James", "Bond"]
    
    Monque.reserve(:specific).should_not be_nil
    Monque.reserve(:specific).should be_nil
  end
  
  it "should enqueue with specific priority" do
    job = Monque.enqueue(GoodJob, "James", "Bond", :job_options => {:priority => 2})
    job.priority.should == 2
  end
  
  it "should override queue through the queue option" do
    job = Monque.enqueue(GoodSpecificQueueJob, :job_options => {:queue => "overridden"})
    job.queue_name.should == "overridden"
  end
  
  pending "should reserve jobs in order of priority and time of enqueuing" do
    Monque.enqueue(GoodJob, "1", :job_options => {:priority => 0})
    Monque.enqueue(GoodJob, "2", :job_options => {:priority => 1})
    Monque.enqueue(GoodJob, "3", :job_options => {:priority => 2})
    Monque.enqueue(GoodJob, "4", :job_options => {:priority => 2})
    Monque.enqueue(GoodJob, "5", :job_options => {:priority => 1})
    Monque.enqueue(GoodJob, "6", :job_options => {:priority => 0})
    
    Monque.reserve.args.first.should == "3"
    Monque.reserve.args.first.should == "4"
    Monque.reserve.args.first.should == "2"
    Monque.reserve.args.first.should == "5"
    Monque.reserve.args.first.should == "1"
    Monque.reserve.args.first.should == "6"
    Monque.reserve.should be_nil
  end
  
  it "should add indexes to queue collections" do
    indexes = Monque.queue("default").index_information.collect { |key, value| value["key"].keys.first }
    indexes.should include("in_progress", "priority", "run_after")
  end
  
  it "should drop all current queues" do
    Monque.enqueue(GoodJob, :job_options => {:queue => "queue1"})
    Monque.enqueue(GoodJob, :job_options => {:queue => "queue2"})
    
    Monque.db.create_collection("not_a_queue") unless Monque.db.collection_names.include?("not_a_queue")
    Monque.db.collection("not_a_queue").insert({:should => "remain"})
    
    Monque.drop
    
    Monque.queue("queue1").size.should == 0
    Monque.queue("queue2").size.should == 0
    Monque.db.collection("not_a_queue").size.should == 1
    
    Monque.db.collection("not_a_queue").drop
  end
  
  it "should return the names of all the current queues" do
    Monque.db.create_collection("not_a_queue") unless Monque.db.collection_names.include?("not_a_queue")
    
    Monque.enqueue(GoodJob, :job_options => {:queue => "queue1"})
    Monque.enqueue(GoodJob, :job_options => {:queue => "queue2"})
    
    Monque.queues.should == ["queue1", "queue2"]
    
    Monque.db.collection("not_a_queue").drop
  end
end
