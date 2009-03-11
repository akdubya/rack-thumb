require 'rack/thumb'

use Rack::ShowExceptions
use Rack::CommonLogger
use Rack::Thumb
use Rack::Static, :urls => ["/images"], :root => "public"

app = lambda { |env| [200, {"Content-Type" => "text/plain"}, ["Hello World!"]] }

run app