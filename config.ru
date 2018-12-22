require './lib/codebreaker'
use Rack::Static, :urls => ['/assets'], :root => 'public'
run Codebreaker::Racker.new