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
#treat_deprecation_warnings_as_errors true

# These options are used by "elasticsearch-plugin install" and
# passenger::daemon.
if ENV['http_proxy']
  http_proxy ENV['http_proxy']
end
if ENV['https_proxy']
  https_proxy ENV['https_proxy']
end
no_proxy ENV['no_proxy']
