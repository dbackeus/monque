require 'spec_helper'

describe Monque do
  before(:each) do
    Monque.drop
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
    
    Monque.reserve.record.values.should include(*job.record.values)
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
  
  it "should remove jobs from queue" do
    job = Monque.enqueue(GoodJob)
    Monque.queue(:default).size.should == 1
    job.destroy
    Monque.queue(:default).size.should == 0
  end
  
  it "should enqueue with specific priority" do
    job = Monque.enqueue(GoodJob, "James", "Bond", :job_options => {:priority => 2})
    job.priority.should == 2
  end
  
  it "should override queue through the queue option" do
    job = Monque.enqueue(GoodSpecificQueueJob, :job_options => {:queue => "overridden"})
    job.queue_name.should == "overridden"
  end
  
  it "should reserve jobs in order of priority" do
    Monque.enqueue(GoodJob, :job_options => {:priority => 0})
    Monque.enqueue(GoodJob, :job_options => {:priority => 1})
    Monque.enqueue(GoodJob, :job_options => {:priority => 2})
    Monque.enqueue(GoodJob, :job_options => {:priority => 2})
    Monque.enqueue(GoodJob, :job_options => {:priority => 1})
    Monque.enqueue(GoodJob, :job_options => {:priority => 0})
    
    Monque.reserve.priority.should == 2
    Monque.reserve.priority.should == 2
    Monque.reserve.priority.should == 1
    Monque.reserve.priority.should == 1
    Monque.reserve.priority.should == 0
    Monque.reserve.priority.should == 0
    Monque.reserve.should be_nil
  end
  
  it "should add indexes to queue collections" do
    Monque.queue("default").index_information.values.flatten.should include("in_progress", "priority")
  end
  
  it "should drop all current queues" do
    Monque.enqueue(GoodJob, :job_options => {:queue => "queue1"})
    Monque.enqueue(GoodJob, :job_options => {:queue => "queue2"})
    Monque.enqueue(GoodJob, :job_options => {:queue => "queue3"})
    
    Monque.db.create_collection("not_a_queue")
    Monque.db.collection("not_a_queue").insert({:should => "remain"})
    
    Monque.drop
    
    Monque.queue("queue1").size.should == 0
    Monque.queue("queue2").size.should == 0
    Monque.queue("queue3").size.should == 0
    
    Monque.db.collection("not_a_queue").size.should == 1
  end
end
