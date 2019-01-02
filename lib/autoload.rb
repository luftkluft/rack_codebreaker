require_relative 'constants'
require_relative 'codebreaker/version'
require 'erb'
require 'codebreaker_web'
require 'date'
require 'yaml'
require 'i18n'

I18n.load_path << Dir[File.expand_path('lib/messages/') + '/*.yml']
I18n.config.available_locales = :en
