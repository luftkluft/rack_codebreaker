require_relative 'codebreaker/version'
require 'erb'
require 'codebreaker_web'

module Codebreaker
  class Racker
    def call(env)
      request = Rack::Request.new(env)
      case request.path
      when '/' then Rack::Response.new(render('menu.html.erb'))
      else Rack::Response.new('Not Found', 404)
      end
    end

    private

    def render(template)
      path = File.expand_path("../views/#{template}", __FILE__)
      ERB.new(File.read(path)).result(binding)
    end
  end
end
