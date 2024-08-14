source 'https://rubygems.org'

ruby "~> #{File.read(File.join(__dir__, '.ruby-version')).strip}"

group :development do
  gem 'colorize'
  gem 'pry'
  gem 'pry-byebug', '>= 3.9'

  # used for salesforcelib
  gem 'restforce'
  gem 'ruby-keychain'
  gem 'sinatra'
  gem 'warning'
  gem 'rackup'
end

gem 'activesupport'
gem 'aws-sdk', '>= 3.0'
gem 'aws-sdk-secretsmanager', '>=1.20'

group :analytics_utilities do
  gem 'aws-sdk-redshiftdataapiservice', '>=1.41'
end

gem 'rake'
gem 'csv'

gem 'rest-client', '>= 2.0'
gem 'ruby-progressbar'
gem 'semantic'
gem 'subprocess'
gem 'terminal-table', '>= 3.0'
gem 'thor', '>= 0.19'
gem 'tty-prompt', '>= 0.14'

gem 'terraform_landscape', '>= 0.1'

# used for modules/bootstrap templates
gem 'erubis', '>= 2'

group :test do
  gem 'rspec', '>= 3.0'
  gem 'cookstyle', '>= 7.32.1'
end
