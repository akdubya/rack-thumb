require 'bacon'
require File.dirname(File.dirname(__FILE__)) + '/lib/rack/thumb'
require 'rack/mock'

class String
  def each(*args, &block)
    each_line(*args, &block)
  end
end