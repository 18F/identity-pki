require './lib/yaml_key_checker'

task :default => [:help]

desc 'Run entire test suite'
task :test do
  Rake::Task['login:check_app_yml_keys'].invoke
end

task :help do
  puts "Executing rake -T to view available tasks:\n\n"
  puts %x[rake -T]
end

namespace :login do
  desc 'Validates current templates against application.yml.example ' \
       'in the official login.gov IdP repository'
  task :check_app_yml_keys do
    checker = YamlKeyChecker.new
    checker.validate!
  end
end
