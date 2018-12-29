WIN = '++++'.freeze
LOSE = 'lose'.freeze
SCORE_DATABASE = './lib/data/score.yml'.freeze
HISTORY_DATABASE = './lib/data/history.yml'.freeze
NUMBER_OF_DIJITS = 4
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
