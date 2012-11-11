require 'minitest/spec'
require 'minitest/autorun'
require 'turn/autorun'
require 'rack/mock'
require 'rack/thumb'

class String
  def each(*args, &block)
    each_line(*args, &block)
  end
end

def verify_response(res, content_type, dim)
  res.status.must_equal 200
  res.content_type.must_equal content_type
  image_dimensions(res).must_equal dim
end

def verify_bad_response(res, status, body)
  res.status.must_equal status
  res.body.must_equal body
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

def tempfile(body)
  Tempfile.new('foo.jpg').tap {|f| f.binmode; f.write(body); f.close }
end

def image_info(body)
  Mapel.info(tempfile(body).path)
end

def image_dimensions(response)
  image_info(response.body)[:dimensions]
end

def signature
  Digest::SHA1.hexdigest("/media/imagick_50x100-sw.jpg#{credentials[:secret]}")[0...credentials[:keylength]]
end