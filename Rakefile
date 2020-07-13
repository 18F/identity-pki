require 'bundler/setup'
require 'semantic'

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
  #Rake::Task['integration:vagrant_nodes'].invoke(args.cookbook)
  Rake::Task['integration:ec2_nodes'].invoke(args.node)
end

task :help do
  puts "Executing rake -T to view available tasks:\n\n"
  puts %x[rake -T]
end

def set_version(version, message)
  File.write('VERSION.txt', "#{version}\n")
  sh 'git add VERSION.txt'
  sh "git commit -m '#{message}'"
end

desc 'Cut a release and bump the release version in VERSION.txt'
task :release do
  version_re = /\A((?<pre>\w+)-)?(?<major>\d+)(\.(?<hf>\d+))?\z/
  current_raw = File.read('VERSION.txt').strip
  match = version_re.match(current_raw)
  unless match
    puts "Version #{current_raw.inspect} does not match expected version regex"
    exit 1
  end

  pre = match[:pre]
  major = Integer(match[:major])
  hf = Integer(match[:hf]) if match[:hf]

  if pre
    release_version = major
  elsif hf
    release_version = "#{major}.#{hf}"
  else
    release_version = major + 1
  end

  puts "Cutting release: #{current_raw.inspect} -> #{release_version.to_s.inspect}.\n"

  puts "Cutting #{release_version.inspect} release."
  set_version(release_version, "Release version #{release_version}")
  sh "git tag 'v#{release_version}'"

  if hf
    post_release_version = "pre-#{major + 1}"
  else
    post_release_version = "pre-#{release_version + 1}"
  end
  puts "Setting version to #{post_release_version.inspect} post release."
  set_version(post_release_version,
              "Post release version #{post_release_version}")
end

desc 'Cut a hotfix and bump the release version in VERSION.txt'
task :hotfix do
  version_re = /\A((?<pre>\w+)-)?(?<major>\d+)(\.(?<hf>\d+))?\z/
  current_raw = File.read('VERSION.txt').strip
  match = version_re.match(current_raw)
  unless match
    puts "Version #{current_raw.inspect} does not match expected version regex"
    exit 1
  end

  pre = match[:pre]
  major = match[:major]
  hf = Integer(match[:hf]) if match[:hf]

  # Retain pre-release name if set
  if pre
    release_version = "#{pre}-#{major}"
  else
    release_version = major
  end
  
  if hf
    release_version = "#{release_version}.#{hf + 1}"
  else
    release_version = "#{release_version}.1"
  end

  puts "Cutting release: #{current_raw.inspect} -> #{release_version.to_s.inspect}.\n"

  puts "Cutting #{release_version.inspect} release."
  set_version(release_version, "Release version #{release_version}")
  sh "git tag 'v#{release_version}'"

  # No post-release version for hotfixes!
end

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

desc 'Runs ChefSpec tests on all cookbooks with unit tests'
namespace :unit do
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
end

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

desc 'Runs Test Kitchen vagrant tests on all cookbooks with that configuration'
namespace :integration do
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
end

desc 'Runs Test Kitchen ec2 tests on all cookbooks with that configuration'
namespace :integration do
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
end

desc 'Runs Test Kitchen vagrant tests on all nodes with integration tests'
namespace :integration do
  task :vagrant_nodes, [:node] do |t, args|
    if args.node
      puts "Running test kitchen vagrant integration tests for #{args.node} node..."
      run_test_kitchen(File.join("nodes", args.node), ".kitchen.vagrant.yml")
    else
      puts "Running test kitchen vagrant integration tests for all nodes..."
      run_test_kitchen_all("nodes", ".kitchen.vagrant.yml")
    end
    puts "All vagrant integration tests passed!"
  end
end

desc 'Runs Test Kitchen ec2 tests on all nodes with integration tests'
namespace :integration do
  task :ec2_nodes, [:node] do |t, args|
    if args.node
      puts "Running test kitchen ec2 integration tests for #{args.node} node..."
      run_test_kitchen(File.join("nodes", args.node), ".kitchen.yml")
    else
      puts "Running test kitchen ec2 integration tests for all nodes..."
      run_test_kitchen_all("nodes", ".kitchen.yml")
    end
    puts "All ec2 integration tests passed!"
  end
end
