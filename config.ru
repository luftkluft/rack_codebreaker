require './lib/codebreaker'

use Rack::Reloader
use Rack::Session::Cookie, key: 'rack.session', secret: 'secret'
use Rack::Static, urls: ['/assets'], root: 'public'
run Codebreaker::Racker
