RSpec.describe Codebreaker::Racker do
  describe 'vesion number' do
    it 'has a version number' do
      expect(Codebreaker::VERSION).not_to be nil
    end
  end

  include Rack::Test::Methods
  def app
    Rack::Builder.parse_file('config.ru').first
  end

  describe '#routs' do
    context 'when response /' do
      let(:response) { get '/' }
      let(:path)     { File.expand_path('../lib/views/menu.html.erb', __dir__) }

      it 'returns status 200 ' do
        expect(response.status).to eq 200
      end

      it 'content include Codebreaker 2018' do
        response
        expect(last_response.body).to include('Codebreaker 2018')
      end
    end
  end
end
