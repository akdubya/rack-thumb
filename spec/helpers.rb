require 'rubygems'
require 'bacon'
require File.dirname(File.dirname(__FILE__)) + '/lib/rack/thumb'
require 'rack/mock'

class String
  def each(*args, &block)
    each_line(*args, &block)
  end
end

def tempfile(body)
  Tempfile.new("foo.jpg").tap do |f|
    f.binmode
    f.write(body)
    f.close
  end
end

def image_info(body)
  Mapel.info(tempfile(body).path)
end

def file_app
  @file_app ||= Rack::File.new(::File.dirname(__FILE__))
end

def request(options = {})
  thumb_app = Rack::Thumb.new(file_app, options)
  Rack::MockRequest.new(thumb_app)
end

def credentials
  {:keylength => 16, :secret => "test"}
end

def file_content(file_path = "/media/imagick.jpg")
  ::File.read(::File.dirname(__FILE__) + file_path)
end

def dimensions(response)
  image_info(response.body)[:dimensions]
end

Bacon.summary_on_exit