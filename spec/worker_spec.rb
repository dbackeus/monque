require 'spec_helper'

module Monque
  describe Worker do
    before(:each) do
      Monque.drop
      @worker = Worker.new
    end
  
    it "should perform jobs" do
      Monque.enqueue(GoodJob, "James", "Bond")
      GoodJob.should_receive(:perform).with("James", "Bond")
      
      @worker.work
      
      Monque.queue(:default).size.should == 0
    end
    
    it "should fail jobs" do
      Monque.enqueue(BadJob)

      start_time = Time.now
      @worker.work
      
      Monque.queue(:default).size.should == 1
      
      failed = Monque.first
      failed.attempts.should == 1
      failed.run_after.should >= start_time + 55
      failed.run_after.should <= Time.now + 60
      failed.last_error.should include("epic fail")
    end
    
    it "should fail jobs with no perform method" do
      Monque.enqueue(JobWithoutPerform)
      
      @worker.work
      
      Monque.queue(:default).size.should == 1
      
      failed = Monque.first
      failed.attempts.should == 1
      failed.last_error.should include("perform")
    end
    
    it "should perform or fail all availible jobs" do
      Monque.enqueue(SimpleJob)
      Monque.enqueue(BadJob)
      Monque.enqueue(SimpleJob)
      Monque.enqueue(SimpleJob)
      
      @worker.work
      
      Monque.queue(:default).size.should == 1
    end
    
    it "should work on the default queue by default" do
      Monque.enqueue(SimpleJob)
      Monque.enqueue(SimpleJob)
      Monque.enqueue(GoodSpecificQueueJob, "Luke", "Skywalker")
      Monque.enqueue(GoodSpecificQueueJob, "Luke", "Skywalker")
      
      @worker.work
      
      Monque.queue(:specific).size.should == 2
      Monque.queue(:default).size.should == 0
    end
    
    it "should work on the specified queue" do
      worker = Worker.new(:specific)
      
      Monque.enqueue(SimpleJob)
      Monque.enqueue(SimpleJob)
      Monque.enqueue(GoodSpecificQueueJob, "Luke", "Skywalker")
      Monque.enqueue(GoodSpecificQueueJob, "Luke", "Skywalker")
      Monque.queue(:specific).size.should == 2
      
      worker.work
      
      Monque.queue(:specific).size.should == 0
      Monque.queue(:default).size.should == 2
    end
    
    it "should work on multiple queues" do
      worker = Worker.new(:default, :specific)
      
      Monque.enqueue(SimpleJob)
      Monque.enqueue(SimpleJob)
      Monque.enqueue(GoodSpecificQueueJob, "Luke", "Skywalker")
      Monque.enqueue(GoodSpecificQueueJob, "Luke", "Skywalker", :job_options => {:queue => :omg})
      
      worker.work
      
      Monque.queue(:specific).size.should == 0
      Monque.queue(:default).size.should == 0
      Monque.queue(:omg).size.should == 1
    end
  end
end
