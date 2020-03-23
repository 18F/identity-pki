source 'https://rubygems.org'
git_source(:github) { |repo_name| "https://github.com/#{repo_name}.git" }

ruby '~> 2.6.5'

gem 'rails', '~> 5.2', '>= 5.2.4.2'

gem 'activerecord-import'
gem 'aws-sdk', require: false
gem 'bloomfilter-rb'
gem 'figaro'
gem 'health_check', '>= 3.0.0'
gem 'identity-hostdata', github: '18F/identity-hostdata', branch: 'master'
gem 'mini_cache'
gem 'newrelic_rpm'
gem 'pg'
gem 'pry-rails'
gem 'puma', '~> 3.12'
gem 'rgl'

group :development, :test do
  gem 'bullet'
  gem 'pry-byebug'
  gem 'rspec-rails', '>= 3.8.2'
  gem 'thin'
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'brakeman', require: false
  gem 'bummr', require: false
  gem 'derailed'
  gem 'fasterer', require: false
  gem 'guard-rspec', require: false
  gem 'overcommit', require: false
  gem 'rack-mini-profiler', require: false
  gem 'rails-erd'
  gem 'reek'
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
end

group :test do
  gem 'axe-matchers', '~> 1.3.4'
  gem 'codeclimate-test-reporter', require: false
  gem 'database_cleaner'
  gem 'factory_bot_rails', '>= 5.0.2'
  gem 'fakefs', require: 'fakefs/safe'
  gem 'rails-controller-testing', '>= 1.0.4'
  gem 'shoulda-matchers', '~> 3.0', require: false
  gem 'simplecov'
  gem 'timecop'
  gem 'webmock'
  gem 'zonebie'
end

gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
