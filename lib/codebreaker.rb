require 'c_codebreaker'

module Codebreaker
  class Racker
    def self.call(env)
      new(env).response.finish
    end

    def initialize(env)
      @answer = []
      @mark = []
      @request = Rack::Request.new(env)
      @gate = Interface.new
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
      @request.session[:game] = @gate.start(@request.params['player_name'],
                                            @request.params['level'])
      @game = @request.session[:game]
      @request.session[:attempts_counter] = @game[:attempts]
      @request.session[:opened_hints] = []
      update_status
    end

    def update_status
      @game = @request.session[:game]
      @player_name = @game[:name]
      @level = @game[:level]
      @attempts_count = @game[:attempts]
      @hints_count = @game[:hints_array].size
      @opened_hints = @request.session[:opened_hints]
      Rack::Response.new(render('game.html.erb'))
    end

    def take_hint
      hint = @gate.game_process(Game::HINT_COMMAND, update_data)
      write_hint_to_session(hint.chars.last.to_i)
      show_message(hint)
    end

    def write_hint_to_session(hint)
      return if hint.zero?

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
      @game = @request.session[:game]
      @game[:attempts] -= 1
      answer_route(@gate.game_process(@request.params['number'], update_data))
    end

    def update_data
      @game = @request.session[:game]
      { name: @game[:name],
        level: @game[:level],
        code_array: @game[:code_array],
        hints_array: @game[:hints_array],
        attempts: @game[:attempts],
        difficulty: @game[:difficulty] }
    end

    def answer_route(answer)
      if answer.is_a?(Hash) && answer.size == 7
        win(answer)
      elsif answer.is_a?(Hash) && answer.size == 8
        lose(answer)
      elsif answer.include?('+') || answer.include?('-') || answer.empty?
        @answer = paint_answer(answer)[:answer]
        @mark = paint_answer(answer)[:mark]
        update_status
      else
        show_message(answer)
      end
    end

    def paint_answer(answer)
      @gate.paint_answer(answer)
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
      { head: '', title: '', body: message,
        response_link: TO_HOME, button_text: BUTTON_TEXT_TO_GAME }
    end
  end
end
