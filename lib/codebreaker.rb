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
      @error_text = {}
      @game_init = GameInit.new
    end

    def response
      case @request.path
      when '/' then index
      when '/submit_menu_button' then submit_menu_button
      else
        Rack::Response.new('Not Found', 404)
      end
    end

    private

    def index
      Rack::Response.new(render('menu.html.erb'))
    end

    def submit_menu_button
      @player_name = @request.params['player_name']
      @level = @request.params['level']
      @attempts = @game_init.receive_attempts[@level.to_sym].to_s
      @hints = @game_init.receive_hints[@level.to_sym].to_s
      sending_game_data = { player_name: @player_name, level: @level,
                            attempts: @attempts, hints: @hints }
      menu_render_way(@game_init.check_game_data(sending_game_data))
    end

    def menu_render_way(check_result = '')
      return Rack::Response.new(render('game.html.erb')) if check_result == ''

      @error_text = check_result
      Rack::Response.new(render('errors.html.erb'))
    end

    def render(template)
      path = File.expand_path("../views/#{template}", __FILE__)
      ERB.new(File.read(path)).result(binding)
    end
  end
end
