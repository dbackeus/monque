require 'spec_helper'

module Monque
  describe Job do
    before(:each) do
      Monque.drop
    end
    
    describe "finding jobs" do
      before(:each) do
        Monque.enqueue(SimpleJob, :job_options => {:queue => "queue1"})
        Monque.enqueue(SimpleJob, :job_options => {:queue => "queue2"})
        Monque.enqueue(SimpleJob, :job_options => {:queue => "queue3"})
      end
      
      it "should return all jobs" do
        Monque::Job.all.length.should == 3
      end
    end
    
    it "should know if it's in progress" do
      job = Monque.enqueue(SimpleJob)
      
      job.lock
      job.should be_in_progress
      
      job.unlock
      job.should_not be_in_progress
    end
    
    describe "failing" do
      before(:each) do
        Monque.enqueue(BadJob)
        @job = Monque.reserve
      end
      
      it "should send warnings to logger" do
        Monque.logger.should_receive(:error).twice
        @job.perform
      end
      
      it "should set last_error" do
        @job.perform
        @job.last_error.should_not be_nil
      end
      
      it "should unlock job" do
        @job.perform
        @job.should_not be_in_progress
      end
    end
  end
end
