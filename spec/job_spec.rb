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
  end
end
