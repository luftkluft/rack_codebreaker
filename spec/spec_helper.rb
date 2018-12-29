require 'simplecov'
require 'rubocop-rspec'

SimpleCov.start do
  add_filter '/spec/'
  # minimum_coverage 95
end

require 'bundler/setup'
require 'codebreaker'
require 'rack/test'

HISTORY_DATABASE = './lib/data/history.yml'.freeze

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
