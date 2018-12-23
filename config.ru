require './lib/codebreaker'

app = Rack::Builder.new do
  # use Rack::Session::Cookie, key: 'rack.session',
  # path: '/', secret: 'secret', expire_after: 216_000
  use Rack::Static, urls: ['/assets'], root: 'public'
  run Codebreaker::Racker
end

run app
