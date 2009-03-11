require 'rack/thumb'

use Rack::ShowExceptions
use Rack::CommonLogger
use Rack::Thumb

run Rack::File.new(::File.dirname(__FILE__) + '/public')