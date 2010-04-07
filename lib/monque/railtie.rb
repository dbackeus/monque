module Monque
  class Railtie < Rails::Railtie
    rake_tasks do
      require "monque/tasks"
      
      namespace :monque do
        task :setup => :environment
      end
    end
  end
end
