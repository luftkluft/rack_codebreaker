require './lib/codebreaker'

app = Rack::Builder.new do
  use Rack::Session::Cookie, key: 'rack.session', secret: 'secret'
  use Rack::Static, urls: ['/assets'], root: 'public'
  run Codebreaker::Racker
end

run app
