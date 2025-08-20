Warning[:deprecated] = true

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start 'rails' do
    track_files '{app,lib}/**/*.rb'

    add_group 'Controllers', 'app/controllers'
    add_group 'Services', 'app/services'
    add_group 'Helpers', 'app/helpers'
    add_group 'Models', 'app/models'
    add_filter '/config/'
    add_filter '/k8files/'
    add_filter %r{^/spec/}
    add_filter '/vendor/bundle/'
    add_filter %r{^/db/}
    add_filter %r{^/\.gem/}
    add_filter %r{/vendor/ruby/}
  end
end

ENV['RAILS_ENV'] ||= 'test'

RSpec.configure do |config|
  # see more settings at spec/rails_helper.rb
  config.raise_errors_for_deprecations!
  config.order = :random
  config.color = true
  config.formatter = :documentation

  # allows you to run only the failures from the previous run:
  # rspec --only-failures
  config.example_status_persistence_file_path = './tmp/rspec-examples.txt'

  # show the n slowest tests at the end of the test run
  # config.profile_examples = 10
end

require 'webmock/rspec'
WebMock.disable_net_connect!(allow: [/localhost/, /127\.0\.0\.1/])
