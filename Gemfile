source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gemspec

gem 'codebreaker_web',
    git: 'https://github.com/luftkluft/codebreaker_web',
    branch: 'develop'
gem 'i18n'
gem 'rake'

group :development do
  gem 'fasterer'
  gem 'rubocop'
  gem 'rubocop-rspec'
end

group :test do
  gem 'capybara'
  gem 'rspec', '~> 3.8'
  gem 'simplecov', require: false, group: :test
end