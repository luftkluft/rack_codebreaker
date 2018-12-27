require_relative 'codebreaker/version'
require 'erb'
require 'codebreaker_web'
require_relative 'autoload'

module Codebreaker
  WIN = '++++'.freeze
  LOSE = 'lose'.freeze
  SCORE_DATABASE = './lib/data/score.yml'.freeze
  class Racker
    def self.call(env)
      new(env).response.finish
    end

    def initialize(env)
      File.open(SCORE_DATABASE, 'a') { |f| f.write([].to_yaml) } unless File.exist?(SCORE_DATABASE)
      @answer = ''
      @mark = []
      @level = ''
      @request = Rack::Request.new(env)
      @game_init = GameInit.new
      @process = GameProcess.new
      @rules = Rules.new
      @logics = GameLogics.new
    end

    def response
      case @request.path
      when '/' then index
      when '/submit_menu_button' then submit_menu_button
      when '/submit_hint_button' then submit_hint_button
      when '/rules_button' then rules_button
      when '/update_game' then update_game
      when '/submit_answer_button' then submit_answer_button
      when '/win' then win
      when '/lose' then lose
      when '/statistics' then statistics
      else
        error404
      end
    end

    private

    def index
      Rack::Response.new(render('menu.html.erb'))
    end

    def submit_menu_button
      setup_attempts_session
      setup_hints_session
      setup_player_session
      setup_secret_data
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
      @request.session[:hints_counter_trigger] = false
    end

    def setup_player_session
      @request.session[:player_name] = @request.params['player_name']
      @request.session[:level] = @request.params['level']
    end

    def menu_render
      check_result = @game_init.check_game_data(validated_data)
      return update_game if check_result == ''

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
      @hints_count = if @request.session[:hints_counter].negative?
                       0
                     else
                       @request.session[:hints_counter]
                     end
      Rack::Response.new(render('game.html.erb'))
    end

    def setup_secret_data
      secret_data = @process.create_secret_data
      @request.session[:secret_code] = secret_data[:secret_code]
      @request.session[:hints_array] = secret_data[:hints_array]
    end

    def submit_hint_button
      @request.session[:hints_counter] -= 1 if @request.session[:hints_counter].positive?
      hints_count = @request.session[:hints_counter]
      hints_count -= 1 if @request.session[:hints_counter_trigger] == true
      @request.session[:hints_counter_trigger] = true if @request.session[:hints_counter] <= 0
      hints_array = @request.session[:hints_array]
      show_message(@process.show_hint(hints_count, hints_array))
    end

    def error404
      Rack::Response.new(render('error404.html.erb'))
    end

    def rules_button
      @read_rules = @rules.load_rules
      Rack::Response.new(render('rules.html.erb'))
    end

    def submit_answer_button
      attempts = @request.session[:attempts_counter] -= 1
      secret_code = @request.session[:secret_code]
      guess = @request.params['number']
      @answer = @logics.answer(attempts, secret_code, guess)
      return win if @answer == WIN

      return lose if @answer == LOSE

      paint_answer(@answer)
      update_game
    end

    def paint_answer(answer)
      (0..3).each do |index|
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
      @hints_left = @request.session[:hints] - @request.session[:hints_counter]
      @hints = @request.session[:hints]
      @secret_code = @request.session[:secret_code]
    end

    def save_result
      game = @process.zip_result(preparation_result)

      File.open(SCORE_DATABASE, 'a') { |f| f.write(game.to_yaml) }
    end

    def preparation_result
      { player_name: @request.session[:player_name],
        level: @request.session[:level],
        result: @request.session[:rsult],
        attempts_left: @request.session[:attempts] - @request.session[:attempts_counter],
        attempts: @request.session[:attempts],
        hints_left: @request.session[:hints] - @request.session[:hints_counter],
        hints: @request.session[:hints],
        secret_code: @request.session[:secret_code],
        date: Time.now.strftime('%d-%m-%Y %R') }
    end

    def statistics
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
      Rack::Response.new(render('messages.html.erb'))
    end
  end
end
