require 'rubygems'
require 'thin'
require 'sinatra'
require 'rack/cache'
require 'rack/thumb'

use Rack::Cache,
  :metastore   => 'file:/var/cache/rack/meta',
  :entitystore => 'file:/var/cache/rack/body'
use Rack::Thumb

get '/' do
  "Hello World!"
end