# This chef-client.rb can be used to run in local mode.

repo_root = File.dirname(__FILE__)

local_mode true
log_location STDOUT

chef_repo_path repo_root
cookbook_path [repo_root + '/berks-cookbooks']
