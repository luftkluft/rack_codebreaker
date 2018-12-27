RSpec.describe Codebreaker::Racker do
  before do
    stub_const('Codebreaker::Storage::PATH', 'lib/data/test.yml')
    File.open(Codebreaker::Storage::PATH, 'w')
  end

  after do
    File.delete('lib/data/test.yml')
  end

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
        expect(last_response.body).to include('<select class="custom-select" name="level"')
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

    context 'with Rules page' do
      before { get '/rules_button' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to include('= GAME RULES =') }
    end

    context 'with Statictics page' do
      before do
        allow(Codebreaker::Storage).to receive_message_chain(:stats, :empty?)
        allow(Codebreaker::Storage).to receive_message_chain(:stats, :each_with_index)
        get '/statistics'
      end

      it { expect(last_response).to be_ok }
    end

    context 'with 404 page' do
      before { get '/unknown' }

      it { expect(last_response.body).to include('Page not found.') }
    end
  end

  describe 'Menu submit button click with true params' do
    before do
      get '/'
      post '/submit_menu_button', player_name: 'Name', level: 'hard'
    end

    context 'with setup_player_session' do
      it { expect(last_request.session[:player_name]).to eq('Name') }
      it { expect(last_request.session[:level]).to eq('hard') }
    end

    context 'with setuped hints' do
      it { expect(last_request.session[:hints]).to be 1 }
    end

    context 'with setuped hints_counter' do
      it { expect(last_request.session[:hints_counter]).to be 1 }
    end

    context 'with game page' do
      it 'responses with ok status' do
        expect(last_response).to be_ok
      end

      it 'contains a greeting' do
        expect(last_response.body).to include('Hello, Name!')
      end
    end
  end

  describe 'Answer submit button click' do
    it 'click with number `1234` with decrease attempts counter' do
      get '/'
      post '/submit_menu_button', player_name: 'Name', level: 'hard'
      post '/submit_answer_button', number: '1234'
      expect(last_request.session[:attempts_counter]).to be 4
      expect(last_response.body).to include 'Try to guess 4-digit number'
      expect(last_response).to be_ok
    end

    it 'click with win case and redirect on win page' do
      get '/'
      post '/submit_menu_button', player_name: 'Name', level: 'hard'
      post '/submit_answer_button', number: last_request.session[:secret_code]
      expect(last_response.body).to include('Congratulations, Name!')
    end

    it 'click with lose case and redirect on lose page' do
      get '/'
      post '/submit_menu_button', player_name: 'Name', level: 'hard'
      post '/submit_answer_button', number: '1234'
      post '/submit_answer_button', number: '1234'
      post '/submit_answer_button', number: '1234'
      post '/submit_answer_button', number: '1234'
      post '/submit_answer_button', number: '1234'
      expect(last_response.body).to include('You lose the game!')
    end
  end

  describe 'Hint submit button click ' do
    it 'with decrease hints counter' do
      get '/'
      post '/submit_menu_button', player_name: 'Name', level: 'hard'
      expect(last_request.session[:hints_counter]).to be 1
      post '/submit_hint_button'
      expect(last_request.session[:hints_counter]).to be 0
    end

    it 'with exceeding the hints' do
      get '/'
      post '/submit_menu_button', player_name: 'Name', level: 'hard'
      post '/submit_hint_button'
      post '/submit_hint_button'
      expect(last_response.body).to include('You have no hints!')
    end
  end
end
