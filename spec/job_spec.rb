require 'spec_helper'

module Monque
  describe Job do
    it "should return all jobs" do
      Monque.enqueue(SimpleJob, :job_options => {:queue => "queue1"})
      Monque.enqueue(SimpleJob, :job_options => {:queue => "queue2"})
      Monque.enqueue(SimpleJob, :job_options => {:queue => "queue3"})
      
      all = Monque::Job.all
      all.shift.queue_name.should == "queue1"
      all.shift.queue_name.should == "queue2"
      all.shift.queue_name.should == "queue3"
    end
  end
end
