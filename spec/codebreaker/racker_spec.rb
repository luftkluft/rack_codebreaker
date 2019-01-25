RSpec.describe Codebreaker::Racker do
  before do
    stub_const('Codebreaker::Storage::PATH', TEST_PATH)
    File.open(Codebreaker::Storage::PATH, 'w')
  end

  after do
    File.delete(TEST_PATH)
    File.delete(SCORE_DATABASE) if File.exist?(SCORE_DATABASE)
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
      let(:path)     { File.expand_path(I18n.t('to_menu_path'), __dir__) }

      before { response }

      it 'returns status 200 ' do
        expect(response.status).to eq 200
      end

      it 'Introduction message `Codebreaker 2018`' do
        expect(last_response.body).to include(I18n.t('codebreaker_title'))
      end

      it 'Select ' do
        expect(last_response.body).to include(I18n.t('select_code'))
      end

      it 'with options `Difficulty`' do
        expect(last_response.body).to include(I18n.t('game_level_title'))
      end

      it 'Input with `Name`' do
        expect(last_response.body).to include(I18n.t('input_name'))
      end

      it 'Submit button with `Start the game!` text' do
        expect(last_response.body).to include(I18n.t('start_button'))
      end

      it 'Statistics button' do
        expect(last_response.body).to include(I18n.t('statistics_button'))
      end

      it 'Rules button' do
        expect(last_response.body).to include(I18n.t('read_rules'))
      end
    end

    context 'with Rules page' do
      before { get '/read_rules' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to include(I18n.t('game_rules_title')) }
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

      it { expect(last_response.body).to include(I18n.t('page_not_found')) }
    end
  end

  describe 'Menu submit button click with true params' do
    before do
      get '/'
      post '/start_game', player_name: TEST_NAME, level: TEST_LEVEL
    end

    context 'with setup_player_session' do
      it { expect(last_request.session[:player_name]).to eq(I18n.t('test_name')) }
      it { expect(last_request.session[:level]).to eq(I18n.t('test_level')) }
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
        expect(last_response.body).to include(I18n.t('hello_text'))
        expect(last_response.body).to include(I18n.t('test_name'))
      end
    end
  end

  describe 'Answer submit button click' do
    before do
      get '/'
      post '/start_game', player_name: TEST_NAME, level: TEST_LEVEL
    end

    it 'click with number `1234` decrease attempts counter' do
      post '/start_round', number: TEST_NUMBER
      expect(last_request.session[:attempts_counter]).to be Game::DIGITS_COUNT
      expect(last_response.body).to include I18n.t('shot_rules')
      expect(last_response).to be_ok
    end

    it 'click with win case and redirect on win page' do
      last_request.session[:secret_code]
      post '/start_round', number: last_request.session[:secret_code]
      expect(last_response.body).to include(I18n.t('won_game_text'))
    end

    it 'click with lose case and redirect on lose page' do
      5.times { |_i| post '/start_round', number: TEST_NUMBER }
      expect(last_response.body).to include(I18n.t('lose_game_text'))
    end
  end

  describe 'Hint submit button click ' do
    before do
      get '/'
      post '/start_game', player_name: TEST_NAME, level: TEST_LEVEL
    end

    it 'with decrease hints counter' do
      expect(last_request.session[:hints_counter]).to be 1
      post '/take_hint'
      expect(last_request.session[:hints_counter]).to be 0
    end

    it 'with exceeding the hints' do
      2.times { |_i| post '/take_hint' }
      expect(last_response.body).to include(I18n.t('have_no_hints_message'))
    end
  end
end
