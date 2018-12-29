WIN = '++++'.freeze
LOSE = 'lose'.freeze
SCORE_DATABASE = './lib/data/score.yml'.freeze
HISTORY_DATABASE = './lib/data/history.yml'.freeze
NUMBER_OF_DIJITS = 4
TEST_PATH = 'lib/data/test.yml'.freeze
TEST_NUMBER = '1234'.freeze
TEST_LEVEL = 'hard'.freeze
TEST_NAME = 'Name'.freeze

require_relative 'codebreaker/version'
require 'erb'
require 'codebreaker_web'
require 'date'
require 'yaml'
require 'i18n'

I18n.load_path << Dir[File.expand_path('lib/messages/') + '/*.yml']
I18n.config.available_locales = :en
