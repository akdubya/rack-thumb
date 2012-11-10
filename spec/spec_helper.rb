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