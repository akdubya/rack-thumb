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

def image_info(body)
  t = Tempfile.new('foo.jpg').tap {|f| f.binmode; f.write(body); f.close }
  Mapel.info(t.path)
end

def image_dimensions(response)
  image_info(response.body)[:dimensions]
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