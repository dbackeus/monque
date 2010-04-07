module Monque
  class Railtie < Rails::Railtie
    railtie_name :monque

    rake_tasks do
      require "monque/tasks"
    end
  end
end
