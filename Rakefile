require 'bundler/setup'
require 'semantic'
require './lib/yaml_key_checker'

task :default => [:help]

desc 'Run entire test suite'
task :test do
  Rake::Task['test_cookbooks'].invoke
  Rake::Task['test_nodes'].invoke
end

desc 'Run cookbook tests'
task :test_cookbooks, [:cookbook] do |t, args|
  Rake::Task['unit:cookbooks'].invoke(args.cookbook)
  Rake::Task['integration:vagrant_cookbooks'].invoke(args.cookbook)
  Rake::Task['integration:ec2_cookbooks'].invoke(args.cookbook)
end

desc 'Run node tests'
task :test_nodes, [:node] do |t, args|
  Rake::Task['unit:nodes'].invoke(args.node)
  Rake::Task['integration:vagrant_nodes'].invoke(args.node)
  Rake::Task['integration:ec2_nodes'].invoke(args.node)
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

desc 'Runs regression tests and bump the version by the specified increment'
task :release, [:type] do |t, args|
  release_types = ["major", "minor", "patch"]
  unless release_types.include?(args.type)
    puts <<EOF

Release type must be one of #{release_types}
Example: "rake release[minor]"

This project uses semantic versioning.  See http://semver.org/.

EOF
    exit 1
  end
  current_version = Semantic::Version.new(File.read('VERSION.txt'))

  # If this is a pre release and we are only doing a patch, don't bump anything
  # since bumping the patch version is the default for a pre release.
  if args.type == "patch" && current_version.pre
    release_version = current_version.clone
    release_version.pre = nil
    release_version.build = nil
  else
    release_version = current_version.increment!(args.type)
  end
  puts "Cutting #{args.type} release:\"#{current_version}\" -> \"#{release_version}\".\n"

  def bump_version(version, message)
    File.open('VERSION.txt', 'w') { |file| file.write(version.to_s + "\n") }
    sh "git add VERSION.txt"
    sh "git commit -m \"#{message}\""
  end

  puts "Cutting \"#{release_version}\" release."
  bump_version(release_version, "Release version #{release_version}")
  sh "git tag v#{release_version}"

  post_release_version = release_version.increment!("patch")
  post_release_version.pre = "pre"
  puts "Setting version to \"#{post_release_version}\" post release."
  bump_version(post_release_version, "Post release version #{post_release_version}")
end

desc 'Runs ChefSpec tests on all cookbooks with unit tests'
namespace :unit do
  def run_chefspec(path)
    if File.exists?(File.join(path, "spec"))
      puts "Running chefspec unittests for #{path}..."
      # Use "with_clean_env" to isolate dependencies.
      # See: https://stackoverflow.com/a/16407512.
      Bundler.with_clean_env { sh "cd #{path} && bundle install" }
      Bundler.with_clean_env { sh "cd #{path} && bundle exec rspec" }
    else
      puts "Skipping chefspec test for directory #{path}.  No spec directory found"
    end
  end
  def run_chefspec_all(base_path)
    Dir.foreach(base_path) do |test_dir|
      next if test_dir == '.' || test_dir == '..'
      full_test_dir = File.join(base_path, test_dir)
      run_chefspec(full_test_dir)
    end
  end

  task :cookbooks, [:cookbook] do |t, args|
    if args.cookbook
      puts "Running chefspec tests for #{args.cookbook} cookbook..."
      run_chefspec(File.join("kitchen/cookbooks", args.cookbook))
    else
      puts "Running chefspec tests for all cookbooks..."
      run_chefspec_all("kitchen/cookbooks")
    end
    puts "All chefspec tests passed!"
  end
  task :nodes, [:node] do |t, args|
    if args.node
      puts "Running chefspec tests for #{args.node} node..."
      run_chefspec(File.join("nodes", args.node))
    else
      puts "Running chefspec tests for all nodes..."
      run_chefspec_all("nodes")
    end
    puts "All chefspec tests passed!"
  end
end

desc 'Runs Test Kitchen tests on all cookbooks with integration tests'
namespace :integration do
  def run_test_kitchen(path, config_filename)
    puts "Running test kitchen integration test for #{path}..."
    # Use "with_clean_env" to isolate dependencies.
    # See: https://stackoverflow.com/a/16407512.
    Bundler.with_clean_env { sh "cd #{path} && bundle install" }
    Bundler.with_clean_env { sh "cd #{path} && bundle exec env KITCHEN_YAML=#{config_filename} kitchen test" }
  end

  def run_test_kitchen_all(base_path, config_filename)
    Dir.foreach(base_path) do |test_dir|
      next if test_dir == '.' || test_dir == '..'
      full_test_dir = File.join(base_path, test_dir)
      if File.exists?(File.join(full_test_dir, config_filename))
        run_test_kitchen(full_test_dir, config_filename)
      else
        puts "Skipping integration test for directory #{test_dir}.  No #{config_filename} found"
      end
    end
  end

  task :vagrant_cookbooks, [:cookbook] do |t, args|
    puts "Running test kitchen vagrant integration tests for all cookbooks..."
    if args.cookbook
      puts "Running test kitchen vagrant integration tests for #{args.cookbook} cookbook..."
      run_test_kitchen(File.join("kitchen/cookbooks", args.cookbook), ".kitchen.yml")
    else
      puts "Running test kitchen vagrant integration tests for all cookbooks..."
      run_test_kitchen_all("kitchen/cookbooks", ".kitchen.yml")
    end
    puts "All vagrant integration tests passed!"
  end
  task :ec2_cookbooks, [:cookbook] do |t, args|
    if args.cookbook
      puts "Running test kitchen ec2 integration tests for #{args.cookbook} cookbook..."
      run_test_kitchen(File.join("kitchen/cookbooks", args.cookbook), ".kitchen.cloud.yml")
    else
      puts "Running test kitchen ec2 integration tests for all cookbooks..."
      run_test_kitchen_all("kitchen/cookbooks", ".kitchen.cloud.yml")
    end
    puts "All ec2 integration tests passed!"
  end
  task :vagrant_nodes, [:node] do |t, args|
    if args.node
      puts "Running test kitchen vagrant integration tests for #{args.node} node..."
      run_test_kitchen(File.join("nodes", args.node), ".kitchen.yml")
    else
      puts "Running test kitchen vagrant integration tests for all nodes..."
      run_test_kitchen_all("nodes", ".kitchen.yml")
    end
    puts "All vagrant integration tests passed!"
  end
  task :ec2_nodes, [:node] do |t, args|
    if args.node
      puts "Running test kitchen ec2 integration tests for #{args.node} node..."
      run_test_kitchen(File.join("nodes", args.node), ".kitchen.cloud.yml")
    else
      puts "Running test kitchen ec2 integration tests for all nodes..."
      run_test_kitchen_all("nodes", ".kitchen.cloud.yml")
    end
    puts "All ec2 integration tests passed!"
  end
end
