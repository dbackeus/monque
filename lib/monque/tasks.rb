# require 'monque/tasks'
# will give you the monque tasks

namespace :monque do
  desc "Start a Monque worker (ex. QUEUE=this,that rake monque:work)"
  task :work do
    require 'monque'
    
    queues = (ENV['QUEUES'] || ENV['QUEUE']).to_s.split(',')
    worker = Monque::Worker.new(*queues)

    puts "*** Starting worker #{worker}"

    worker.work(ENV['INTERVAL'] || 5) # interval, will block
  end

  desc "Start multiple Monque workers. Should only be used in dev mode. (ex. COUNT=2 rake monque:workers)"
  task :workers do
    threads = []

    ENV['COUNT'].to_i.times do
      threads << Thread.new do
        system "rake monque:work"
      end
    end

    threads.each { |thread| thread.join }
  end
end
