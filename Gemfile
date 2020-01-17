source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gemspec

gem 'c_codebreaker',
    git: 'https://github.com/luftkluft/c_codebreaker',
    branch: 'develop'

gem 'i18n'
gem 'rack'

group :development do
  gem 'fasterer'
  gem 'pry'
  gem 'rubocop'
  gem 'rubocop-rspec'
end

group :test do
  gem 'rack-test', require: 'rack/test'
  gem 'rspec', '~> 3.8'
  gem 'simplecov', require: false, group: :test
end
