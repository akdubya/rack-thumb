# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'rack/thumb/version'

Gem::Specification.new do |gem|
  gem.name          = "rack-thumb"
  gem.version       = Rack::Thumb::VERSION
  gem.authors       = ["Aleksander Williams"]
  gem.email         = %q{alekswilliams@earthlink.net}
  gem.description   = %q{Rack::Thumb is drop-in dynamic thumbnailing middleware for Rack-based applications, featuring simple configuration, optional security (via url-signing), and maximum flexibility.}
  gem.summary       = %q{Drop-in image thumbnailing for your Rack stack.}
  gem.homepage      = %q{http://github.com/akdubya/rack-thumb}

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end