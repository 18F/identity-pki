require './lib/yaml_key_checker'

task :default => [:help]

desc 'Run entire test suite'
task :test do
  Rake::Task['unit'].invoke
  Rake::Task['integration'].invoke
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

desc 'Runs ChefSpec tests on all cookbooks with unit tests'
task :unit do |t, args|
  Dir.glob('kitchen/cookbooks/*/spec') do |cookbook_spec|
    cookbook = File.dirname(cookbook_spec)
    sh "cd #{cookbook} && bundle install"
    sh "cd #{cookbook} && bundle exec rspec"
  end
end

desc 'Runs Test Kitchen tests on all cookbooks with integration tests'
task :integration do |t, args|
  Dir.glob('kitchen/cookbooks/*/.kitchen.yml') do |cookbook_spec|
    cookbook = File.dirname(cookbook_spec)
    sh "cd #{cookbook} && bundle install"
    sh "cd #{cookbook} && bundle exec kitchen test"
  end
end
