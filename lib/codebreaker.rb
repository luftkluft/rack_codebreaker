require_relative 'autoload'

module Codebreaker
  class Racker
    def self.call(env)
      new(env).response.finish
    end

    def initialize(env)
      @answer = ''
      @mark = []
      @request = Rack::Request.new(env)
      @game_init = GameInit.new
      @process = GameProcess.new
      @rules = Rules.new
      @logics = GameLogics.new
    end

    def response
      case @request.path
      when '/' then index
      when '/start_game' then start_game
      when '/take_hint' then take_hint
      when '/read_rules' then read_rules
      when '/start_round' then start_round
      when '/statistics' then statistics
      else
        error404
      end
    end

    private

    def index
      return Rack::Response.new(render('menu.html.erb')) unless File.exist?(HISTORY_DATABASE)

      read_status
    end

    def start_game
      unless File.exist?(HISTORY_DATABASE)
        setup_attempts_session
        setup_hints_session
        setup_player_session
        setup_secret_data
      end
      write_status
      menu_render
    end

    def setup_attempts_session
      @level = @request.params['level']
      @request.session[:attempts] = @game_init.receive_attempts[@level.to_sym]
      @request.session[:attempts_counter] = @request.session[:attempts]
    end

    def setup_hints_session
      @request.session[:hints] = @game_init.receive_hints[@level.to_sym]
      @request.session[:hints_counter] = @request.session[:hints]
      @request.session[:hints_count] = @request.session[:hints]
      @request.session[:opened_hints] = []
    end

    def setup_player_session
      @request.session[:player_name] = @request.params['player_name']
      @request.session[:level] = @request.params['level']
    end

    def menu_render
      check_result = @game_init.check_game_data(validated_data)
      return update_game if check_result.empty?

      @messages_text = check_result
      Rack::Response.new(render('messages.html.erb'))
    end

    def validated_data
      { player_name: @request.session[:player_name] }
    end

    def update_game
      @player_name = @request.session[:player_name]
      @level = @request.session[:level]
      @attempts_count = @request.session[:attempts_counter]
      @request.session[:hints_counter]
      @request.session[:hints_count] = @request.session[:hints_counter]
      @request.session[:hints_count] = 0 if @request.session[:hints_counter] <= 0
      @opened_hints = @request.session[:opened_hints]
      @hints_count = @request.session[:hints_count]
      Rack::Response.new(render('game.html.erb'))
    end

    def setup_secret_data
      secret_data = @process.create_secret_data
      @request.session[:secret_code] = secret_data[:secret_code]
      @request.session[:hints_array] = secret_data[:hints_array]
    end

    def take_hint
      @request.session[:hints_counter] -= 1
      hints_count_to_lib = @request.session[:hints_counter]
      hints_array = @request.session[:hints_array]
      show_message(@process.show_hint(hints_count_to_lib, hints_array))
    end

    def error404
      Rack::Response.new(render('error404.html.erb'))
    end

    def read_rules
      @read_rules = @rules.load_rules
      Rack::Response.new(render('rules.html.erb'))
    end

    def start_round
      attempts = @request.session[:attempts_counter] -= 1
      secret_code = @request.session[:secret_code]
      guess = @request.params['number']
      @answer = @logics.answer(attempts, secret_code, guess)
      return win if @answer == WIN

      return lose if @answer == LOSE

      paint_answer(@answer)
      write_status
      update_game
    end

    def paint_answer(answer)
      NUMBER_OF_DIJITS.times do |index|
        next @mark[index] = 'success' if answer[index] == '+'
        next @mark[index] = 'primary' if answer[index] == '-'

        answer[index] = 'x'
        @mark[index] = 'danger'
      end
      answer
    end

    def win
      @request.session[:rsult] = WIN
      summarizing
      save_result
      Rack::Response.new(render('win.html.erb'))
    end

    def lose
      @request.session[:rsult] = LOSE
      summarizing
      save_result
      Rack::Response.new(render('lose.html.erb'))
    end

    def summarizing
      @player_name = @request.session[:player_name]
      @level = @request.session[:level]
      @attempts_left = @request.session[:attempts] - @request.session[:attempts_counter]
      @attempts = @request.session[:attempts]
      @request.session[:hints_count]
      @hints_left = @request.session[:hints] - @request.session[:hints_count]
      @hints = @request.session[:hints]
      @secret_code = @request.session[:secret_code]
    end

    def preparation_common_data
      { player_name: @request.session[:player_name],
        level: @request.session[:level],
        attempts: @request.session[:attempts],
        hints: @request.session[:hints],
        secret_code: @request.session[:secret_code] }
    end

    def preparation_hystory
      { attempts_counter: @request.session[:attempts_counter],
        hints_counter: @request.session[:hints_counter],
        opened_hints: @request.session[:opened_hints],
        hints_count: @request.session[:hints_count] }
    end

    def preparation_result
      { result: @request.session[:rsult],
        attempts_left: @request.session[:attempts] - @request.session[:attempts_counter],
        hints_left: @request.session[:hints] - @request.session[:hints_counter],
        date: Time.now.strftime('%d-%m-%Y %R') }
    end

    def save_result
      result = [*preparation_common_data, *preparation_result].to_h
      game = @process.zip_result(result)
      File.open(SCORE_DATABASE, 'a') { |f| f.write(game.to_yaml) }
      File.delete(HISTORY_DATABASE)
    end

    def write_status
      history = [*preparation_common_data, *preparation_hystory].to_h
      File.open(HISTORY_DATABASE, 'w') { |f| f.write(history.to_yaml) }
    end

    def read_status
      game = YAML.load_stream(File.open(HISTORY_DATABASE, 'r'))
      game[0][:player_name]
      @request.session[:player_name] = game[0][:player_name]
      @request.session[:level] = game[0][:level]
      @request.session[:attempts] = game[0][:attempts]
      @request.session[:attempts_counter] = game[0][:attempts_counter]
      @request.session[:hints] = game[0][:hints]
      @request.session[:hints_counter] = game[0][:hints_counter]
      @request.session[:secret_code] = game[0][:secret_code]
      @request.session[:opened_hints] = game[0][:opened_hints]
      @request.session[:hints_count] = game[0][:hints_count]
      update_game
    end

    def statistics
      File.open(SCORE_DATABASE, 'a') { |f| f.write([].to_yaml) } unless File.exist?(SCORE_DATABASE)
      file = File.open(SCORE_DATABASE, 'r')
      results = YAML.load_stream(file)
      @sorted_results = @process.raiting(results)
      Rack::Response.new(render('statistics.html.erb'))
    end

    def render(template)
      path = File.expand_path("../views/#{template}", __FILE__)
      ERB.new(File.read(path)).result(binding)
    end

    def show_message(message)
      @messages_text = message
      if @messages_text[:head] == I18n.t('your_hint')
        @request.session[:opened_hints] << @messages_text[:title]
      end
      write_status
      Rack::Response.new(render('messages.html.erb'))
    end
  end
end
