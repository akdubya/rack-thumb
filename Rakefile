require 'rubygems'
require 'rake'

name = 'rack-thumb'
version = '0.2.4'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = name
    gem.version = version
    gem.summary = %Q{Drop-in image thumbnailing for your Rack stack.}
    gem.email = "alekswilliams@earthlink.net"
    gem.homepage = "http://github.com/akdubya/rack-thumb"
    gem.authors = ["Aleksander Williams"]
    gem.add_dependency "rack", ">= 0"
    gem.add_dependency "mapel", ">= 0.1.6"
    gem.add_development_dependency "bacon", ">= 0"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |spec|
    spec.libs << 'spec'
    spec.pattern = 'spec/**/*_spec.rb'
    spec.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :spec => :check_dependencies

task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "rack-thumb #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end