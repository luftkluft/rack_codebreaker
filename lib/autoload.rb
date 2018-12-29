require_relative 'codebreaker/version'
require 'erb'
require 'codebreaker_web'
require 'date'
require 'yaml'
require 'i18n'
require 'simplecov'
require 'rubocop-rspec'
require 'bundler/setup'
require 'codebreaker'
require 'rack/test'

I18n.load_path << Dir[File.expand_path('lib/messages/') + '/*.yml']
I18n.config.available_locales = :en
