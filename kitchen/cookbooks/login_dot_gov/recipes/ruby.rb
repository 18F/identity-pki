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

file '/etc/environment' do
  content <<-EOM
# Dropped off by chef
# This is a static file (not script) used by PAM to set env variables.
RBENV_ROOT=#{rbenv_root}
PATH="/opt/chef/bin:#{rbenv_root}/shims:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"

RAILS_ENV=production
RACK_ENV=production
  EOM
end

# install dependencies
package 'libpq-dev'
package 'libsasl2-dev'
package 'ruby-dev'
