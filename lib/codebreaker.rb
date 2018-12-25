require_relative 'codebreaker/version'
require 'erb'
require 'codebreaker_web'
require_relative 'autoload'

module Codebreaker
  class Racker
    def self.call(env)
      new(env).response.finish
    end

    def initialize(env)
      @request = Rack::Request.new(env)
      @game_init = GameInit.new
      @process = GameProcess.new
    end

    def response
      case @request.path
      when '/' then index
      when '/submit_menu_button' then submit_menu_button
      when '/submit_hint_button' then submit_hint_button
      when '/update_game' then update_game
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

    def setup_player_session
      @request.session[:play_date] = Date.today
      @request.session[:player_name] = @request.params['player_name']
      @request.session[:level] = @request.params['level']
    end

    def setup_hints_session
      @request.session[:hints] = @game_init.receive_hints[@level.to_sym]
      @request.session[:hints_counter] = @request.session[:hints]
    end

    def setup_attempts_session
      @level = @request.params['level']
      @request.session[:attempts] = @game_init.receive_attempts[@level.to_sym]
      @request.session[:attempts_counter] = @request.session[:attempts]
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
      hints_count = @request.session[:hints_counter] -= 1
      hints_array = @request.session[:hints_array]
      show_message(@process.show_hint(hints_count, hints_array))
    end

    def error404
      Rack::Response.new(render('error404.html.erb'))
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
