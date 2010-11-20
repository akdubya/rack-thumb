require 'rubygems'
require 'bacon'
require File.dirname(File.dirname(__FILE__)) + '/lib/rack/thumb'
require 'rack/mock'

class String
  def each(*args, &block)
    each_line(*args, &block)
  end
end

def image_info(body)
  t = Tempfile.new('foo.jpg').tap {|f| f.binmode; f.write(body); f.close }
  Mapel.info(t.path)
end

Bacon.summary_on_exit