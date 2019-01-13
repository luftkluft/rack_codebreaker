require 'c_codebreaker'

module Codebreaker
  class Racker
    def self.call(env)
      new(env).response.finish
    end

    def initialize(env)
      @answer = ''
      @mark = []
      @request = Rack::Request.new(env)
      @gate = Interface.new
      @gate.setup_web_mode
    end

    def response
      case @request.path
      when '/' then index
      when '/start_game' then start_game
      when '/take_hint' then take_hint
      when '/read_rules' then read_rules
      when '/start_round' then start_round
      when '/statistics' then statistics
      else error404
      end
    end

    private

    def index
      return Rack::Response.new(render('menu.html.erb')) unless @request.session[:game]

      update_status
    end

    def start_game
      @request.session[:game] = true
      setup_data = @gate.start(@request.params['player_name'], @request.params['level'])
      @request.session[:setup_data] = setup_data
      @request.session[:player_name] = setup_data[:name]
      @request.session[:level] = setup_data[:level]
      setup_attempts_session(setup_data)
      setup_hints_session(setup_data)
      setup_secret_data(setup_data)
      update_status
    end

    def setup_attempts_session(setup_data)
      @request.session[:attempts] = setup_data[:attempts]
      @request.session[:attempts_counter] = setup_data[:attempts]
    end

    def setup_hints_session(setup_data)
      @request.session[:hints] = setup_data[:hints]
      @request.session[:hints_counter] = setup_data[:hints]
      @request.session[:hints_count] = setup_data[:hints]
      @request.session[:hints_array] = setup_data[:hints_array]
      @request.session[:opened_hints] = []
    end

    def setup_secret_data(setup_data)
      @request.session[:secret_code] = setup_data[:code_array].join
      @request.session[:code_array] = setup_data[:code_array]
    end

    def update_status
      @player_name = @request.session[:player_name]
      @level = @request.session[:level]
      @attempts_count = @request.session[:attempts_counter]
      @request.session[:hints_count] = @request.session[:hints_counter]
      @request.session[:hints_count] = 0 if @request.session[:hints_counter] <= 0
      @opened_hints = @request.session[:opened_hints]
      @hints_count = @request.session[:hints_count]
      Rack::Response.new(render('game.html.erb'))
    end

    def take_hint
      hint = @gate.game_process('hint', update_data)
      write_hint_to_session(hint)
      show_message(hint)
    end

    def write_hint_to_session(hint)
      return unless @request.session[:hints_counter].positive?

      @request.session[:hints_counter] -= 1
      @request.session[:opened_hints] << hint
    end

    def error404
      Rack::Response.new(render('error404.html.erb'))
    end

    def read_rules
      @read_rules = @gate.rules
      Rack::Response.new(render('rules.html.erb'))
    end

    def start_round
      @request.session[:attempts_counter] -= 1
      answer_route(@gate.game_process(@request.params['number'], update_data))
    end

    def update_data
      { name: @request.session[:player_name],
        level: @request.session[:level],
        code_array: @request.session[:code_array],
        hints_array: @request.session[:hints_array],
        attempts: @request.session[:attempts_counter] }
    end

    def answer_route(answer)
      if answer.is_a?(Hash) && answer.size == 7
        win(answer)
      elsif answer.is_a?(Hash) && answer.size == 8
        lose(answer)
      elsif answer.include?('+') || answer.include?('-') || answer.empty?
        @answer = paint_answer(answer)
        update_status
      else
        show_message(answer)
      end
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

    def win(answer)
      @level = answer[:difficulty]
      @attempts_left = answer[:attempts_used]
      @attempts = answer[:all_attempts]
      @hints_left = answer[:hints_used]
      @hints = answer[:all_hints]
      @player_name = answer[:name]
      @request.session.clear
      Rack::Response.new(render('win.html.erb'))
    end

    def lose(answer)
      @level = answer[:difficulty]
      @attempts_left = answer[:attempts_used]
      @attempts = answer[:all_attempts]
      @hints_left = answer[:hints_used]
      @hints = answer[:all_hints]
      @player_name = answer[:name]
      @secret_code = answer[:code]
      @request.session.clear
      Rack::Response.new(render('lose.html.erb'))
    end

    def statistics
      @sorted_results = @gate.stats
      Rack::Response.new(render('statistics.html.erb'))
    end

    def render(template)
      path = File.expand_path("../views/#{template}", __FILE__)
      ERB.new(File.read(path)).result(binding)
    end

    def show_message(message)
      @messages_text = message_wrapper(message)
      Rack::Response.new(render('messages.html.erb'))
    end

    def message_wrapper(message)
      if message.is_a?(Integer)
        { head: '', title: YOUR_HINT_IS, body: message,
          response_link: TO_HOME, button_text: BUTTON_TEXT_TO_GAME }
      elsif message.include?('no hints')
        { head: '', title: HAVE_NO_HINTS, body: '',
          response_link: TO_HOME, button_text: BUTTON_TEXT_TO_GAME }
      else
        { head: '', title:  UNKNOWN_MESSAGE, body: message,
          response_link: TO_HOME, button_text: OOPS }
      end
    end
  end
end
