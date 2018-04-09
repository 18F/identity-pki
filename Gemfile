source 'https://rubygems.org'
git_source(:github) { |repo_name| "https://github.com/#{repo_name}.git" }

ruby '~> 2.3.5'

gem 'rails', '~> 5.1.5'

gem 'pg'

gem 'puma', '~> 3.7'

group :development, :test do
  gem 'bullet'
  gem 'pry-byebug'
  gem 'rspec-rails'
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
end

gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
