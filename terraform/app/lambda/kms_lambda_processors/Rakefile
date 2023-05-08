# frozen_string_literal: true

require 'bundler/setup'
require 'rspec/core/rake_task'

task :default do
  sh 'rake -T'
end

RSpec::Core::RakeTask.new(:spec)

def alias_task(alias_task, original)
  desc "Alias for rake #{original}"
  task alias_task, Rake.application[original].arg_names => original
end
alias_task(:test, :spec)
