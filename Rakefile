$LOAD_PATH.unshift 'lib'
require 'monque/tasks'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "monque"
    gem.summary = %Q{Like Delayed Job it hath priorities. Like Resque it hath a multitude of queues. Unlike them both it persists on MongoDB.}
    gem.description = %Q{Like Delayed Job it hath priorities. Like Resque it hath a multitude of queues. Unlike them both it persists on MongoDB.}
    gem.email = "duztdruid@gmail.com"
    gem.homepage = "http://github.com/dbackeus/monque"
    gem.authors = ["David Backeus"]
    gem.add_dependency "mongo", ">= 1.0"
    gem.add_development_dependency "rspec", ">= 1.3.0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "monque #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
