require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  minimum_coverage 90
end

require 'rubocop-rspec'
require 'bundler/setup'
require 'codebreaker'
require 'rack/test'
require_relative '../lib/autoload'

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
