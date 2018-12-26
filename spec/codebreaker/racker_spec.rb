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

  describe 'Home page' do
    context 'with I see:' do
      let(:response) { get '/' }
      let(:path)     { File.expand_path('../lib/views/menu.html.erb', __dir__) }

      before { response }

      it 'returns status 200 ' do
        expect(response.status).to eq 200
      end

      it 'Introduction message `Codebreaker 2018`' do
        expect(last_response.body).to include('Codebreaker 2018')
      end

      it 'Select ' do
        expect(last_response.body).to include('<select class="custom-select" name="level" required="">')
      end

      it 'with options `Difficulty`' do
        expect(last_response.body).to include(' <option value="">Choose game level...</option>')
      end

      it 'Input with `Name`' do
        expect(last_response.body).to include('placeholder="Your name"')
      end

      it 'Submit button with `Start the game!` text' do
        expect(last_response.body).to include('Start the game!')
      end

      it 'Statistics button' do
        expect(last_response.body).to include('role="button">Statistics')
      end

      it 'Rules button' do
        expect(last_response.body).to include('role="button">Rules')
      end
    end
  end
end
