source 'https://rubygems.org'
git_source(:github) { |repo_name| "https://github.com/#{repo_name}.git" }

ruby '~> 3.0'

gem 'rails', '~> 6.1.4'

gem 'activerecord-import', '>= 1.0.2'
gem 'aws-sdk', require: false
gem 'bloomfilter-rb'
gem 'health_check', '>= 3.0.0'
gem 'identity-hostdata', github: '18F/identity-hostdata', tag: 'v3.4.1'
gem 'identity-logging', github: '18F/identity-logging', tag: 'v0.1.0'
gem 'mini_cache'
gem 'newrelic_rpm'
gem 'pg'
gem 'pry-rails'
gem 'puma', '~> 4.3'
gem 'redacted_struct', '~> 1.0'
gem 'rgl'

group :development, :test do
  gem 'bullet', '>= 6.0.2'
  gem 'pry-byebug'
  gem 'rspec-rails', '>= 3.8.3'
  gem 'thin', '>= 1.8.0'
end

group :development do
  gem 'better_errors', '>= 2.5.1'
  gem 'brakeman', require: false
  gem 'bummr', require: false
  gem 'derailed', '>= 0.1.0'
  gem 'guard-rspec', require: false
  gem 'overcommit', require: false
  gem 'rack-mini-profiler', '>= 1.0.2', require: false
  gem 'rails-erd', '>= 1.6.0'
  gem 'rubocop', require: false
  gem 'rubocop-rails', '>= 2.4.1', require: false
end

group :test do
  gem 'axe-matchers', '~> 1.3.4'
  gem 'database_cleaner'
  gem 'factory_bot_rails', '>= 5.2.0'
  gem 'fakefs', require: 'fakefs/safe'
  gem 'rails-controller-testing', '>= 1.0.4'
  gem 'shoulda-matchers', '~> 3.1', '>= 3.1.3', require: false
  gem 'simplecov', '>= 0.13.0'
  gem 'timecop'
  gem 'webmock'
  gem 'zonebie'
end

gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
