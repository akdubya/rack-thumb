require 'rake'
require 'rake/testtask'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'fileutils'

task :default => [:test]
task :spec => :test

name = 'rack-thumb'
version = '0.2.1'

spec = Gem::Specification.new do |s|
  s.name = name
  s.version = version
  s.summary = "Drop-in image thumbnailing for your Rack stack."
  s.description = "Drop-in image thumbnailing middleware for your Rack stack (Merb, Sinatra, Rails, etc)."
  s.author = "Aleksander Williams"
  s.email = "alekswilliams@earthlink.net"
  s.homepage = "http://github.com/akdubya/rack-thumb"
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.files = %w(Rakefile README.rdoc) + Dir.glob("{lib,spec,example}/**/*")
  s.require_path = "lib"
  s.add_dependency("mapel", ">= 0.1.1")
end

Rake::GemPackageTask.new(spec) do |p|
  p.need_tar = true if RUBY_PLATFORM !~ /mswin/
end

desc "Install as a system gem"
task :install => [ :package ] do
  sh %{sudo gem install pkg/#{name}-#{version}.gem}
end

desc "Uninstall as a system gem"
task :uninstall => [ :clean ] do
  sh %{sudo gem uninstall #{name}}
end

desc "Create a gemspec file"
task :make_spec do
  File.open("#{name}.gemspec", "w") do |file|
    file.puts spec.to_ruby
  end
end

Rake::TestTask.new(:test) do |t|
  t.libs << "spec"
  t.test_files = FileList['spec/*_spec.rb']
  t.verbose = true
end

Rake::RDocTask.new do |t|
  t.rdoc_dir = 'rdoc'
  t.title = "Rack Thumb: Drop-in image thumbnailing for your Rack stack"
  t.options << '--line-numbers' << '--inline-source' << '-A cattr_accessor=object'
  t.options << '--charset' << 'utf-8'
  t.rdoc_files.include('README.rdoc')
  t.rdoc_files.include('lib/rack/rack-thumb.rb')
  t.rdoc_files.include('lib/rack/rack-thumb/*.rb')
end