require './lib/codebreaker'

use Rack::Reloader
use Rack::Session::Cookie, key: 'rack.session', secret: 'secret'
use Rack::Static, urls: ['/assets', '/node_modules'], root: 'public'
run Codebreaker::Racker
