# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rack-thumb}
  s.version = "0.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Aleksander Williams"]
  s.date = %q{2009-03-11}
  s.description = %q{Drop-in image thumbnailing middleware for your Rack stack (Merb, Sinatra, Rails, etc).}
  s.email = %q{alekswilliams@earthlink.net}
  s.files = ["Rakefile", "README.rdoc", "lib/rack", "lib/rack/thumb.rb", "spec/media", "spec/media/imagick.jpg", "spec/base_spec.rb", "spec/helpers.rb", "example/frank.rb", "example/static.ru", "example/public", "example/public/images", "example/public/images/imagick.jpg", "example/file.ru"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/akdubya/rack-thumb}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Drop-in image thumbnailing for your Rack stack.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mapel>, [">= 0.1.1"])
    else
      s.add_dependency(%q<mapel>, [">= 0.1.1"])
    end
  else
    s.add_dependency(%q<mapel>, [">= 0.1.1"])
  end
end
