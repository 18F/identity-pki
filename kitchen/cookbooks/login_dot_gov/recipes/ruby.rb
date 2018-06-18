# Ruby environment / installation

rbenv_root = node.fetch('identity-ruby').fetch('rbenv_root')

# sanity checks that identity-ruby correctly installed ruby in the base AMI
unless File.exist?(rbenv_root)
  raise "Cannot find rbenv_root at #{rbenv_root.inspect} -- was it created in the base AMI?"
end
unless File.exist?(rbenv_root + '/shims/ruby')
  raise "Cannot find ruby shim in rbenv_root under #{rbenv_root.inspect} -- was it created in the base AMI?"
end
unless File.exist?(rbenv_root + '/shims/gem')
  raise "Cannot find gem shim in rbenv_root under #{rbenv_root.inspect} -- was it created in the base AMI?"
end

global_env_vars = {
  'RBENV_ROOT' => rbenv_root,
  'PATH' => "/opt/chef/bin:#{rbenv_root}/shims:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games",
  'RAILS_ENV' => 'production',
  'RACK_ENV' => 'production',
}

# Set proxy environment variables if present in attributes
if node.fetch('login_dot_gov').fetch('proxy_server')
  global_env_vars['http_proxy']           = node.fetch('login_dot_gov').fetch('http_proxy')
  global_env_vars['https_proxy']          = node.fetch('login_dot_gov').fetch('https_proxy')
  global_env_vars['no_proxy']             = node.fetch('login_dot_gov').fetch('no_proxy')
  global_env_vars['NEW_RELIC_PROXY_HOST'] = node.fetch('login_dot_gov').fetch('proxy_server')
  global_env_vars['NEW_RELIC_PROXY_PORT'] = node.fetch('login_dot_gov').fetch('proxy_port')
end

# hack to set all the env variables from /etc/environment such as PATH and
# RAILS_ENV for all subprocesses during this chef run
global_env_vars.each_pair do |key, val|
  ENV[key] = val
end

file '/etc/environment' do
  header = <<-EOM
    # Dropped off by chef
    # This is a static file (not script) used by PAM to set env variables.
  EOM
  content(
    header + global_env_vars.map { |key, val| "#{key}='#{val}'" }.join("\n") \
    + "\n"
  )
end

# install dependencies
package 'libpq-dev'
package 'libsasl2-dev'
