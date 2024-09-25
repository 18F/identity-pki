source 'https://rubygems.org'
git_source(:github) { |repo_name| "https://github.com/#{repo_name}.git" }

ruby '~> 3.3'

gem 'rails', '~> 7.1.0'

gem 'activerecord-import', '>= 1.0.2'
# pod identity requires 3.188.0
# https://docs.aws.amazon.com/eks/latest/userguide/pod-id-minimum-sdk.html
gem 'aws-sdk-core', '>= 3.188.0'
gem 'aws-sdk-s3'
gem 'bloomfilter-rb'
gem 'csv'
gem 'redis'
gem 'identity-hostdata', github: '18F/identity-hostdata', tag: 'v4.0.0'
gem 'identity-logging', github: '18F/identity-logging', tag: 'v0.1.0'
gem 'mini_cache'
gem 'newrelic_rpm', '~> 8.0'
gem 'pg'
gem 'pry-rails'
gem 'puma'
gem 'bootsnap', '~> 1.0', require: false
gem 'redacted_struct', '~> 2.0'
gem 'rgl'

group :development, :test do
  gem 'bullet', '~> 7.1.2'
  gem 'brakeman', require: false
  gem 'listen'
  gem 'pry-byebug'
  gem 'rspec-rails', '~> 6.0'
  gem 'rubocop', require: false
  gem 'rubocop-rails', '>= 2.19.0', require: false
  gem 'rubocop-performance', '~> 1.17', require: false
end

group :development do
  gem 'better_errors', '>= 2.5.1'
end

group :test do
  gem 'axe-matchers', '~> 1.3.4'
  gem 'bundler-audit', require: false
  gem 'factory_bot_rails', '>= 5.2.0'
  gem 'fakefs', require: 'fakefs/safe'
  gem 'rails-controller-testing', '>= 1.0.4'
  gem 'rspec_junit_formatter'
  gem 'shoulda-matchers', '~> 3.1', '>= 3.1.3', require: false
  gem 'simplecov', '>= 0.13.0'
  gem 'webmock'
end

gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
