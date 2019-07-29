# This chef-client.rb can be used to run in local mode.

repo_root = File.dirname(__FILE__)

local_mode true

log_location STDOUT
log_level :info

# Chef 12: monkey patch to use formatter output even when stdout is not a tty.
# For baffling reasons, chef uses different logging output formats when STDOUT
# is a TTY or not. And setting force_formatter here doesn't seem to work. This
# monkey patch makes "formatter" the default log formatter regardless, but
# allows the --force-logger CLI option to still work.
if Chef::VERSION.start_with?('12.')
  class Chef::Client
    def default_formatter
      if !Chef::Config[:force_logger]
        [:doc]
      else
        [:null]
      end
    end
  end
end

chef_repo_path repo_root
cookbook_path [repo_root + '/berks-cookbooks']

InfoDir = '/etc/login.gov/info'
environment File.read(InfoDir + '/env').chomp
json_attribs InfoDir + '/chef-attributes.json'

# Uncomment when preparing to upgrade chef versions
treat_deprecation_warnings_as_errors true

# Note: the http_proxy, https_proxy, and no_proxy config variables may also be
# set by the chef_proxy_env cookbook. This is needed because Test Kitchen
# creates its own chef-client.rb when running chef under kitchen-ec2 and does
# not use this file, but we still need to set appropriate proxy configs.
