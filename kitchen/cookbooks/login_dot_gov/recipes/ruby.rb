# Ruby environment / installation

rbenv_root = node.fetch('identity-ruby').fetch('rbenv_root')
default_ruby_path = node.fetch('login_dot_gov').fetch('default_ruby_path')

# sanity checks that identity-ruby correctly installed ruby in the base AMI
unless File.exist?(rbenv_root)
  raise "Cannot find rbenv_root at #{rbenv_root.inspect} -- was it created in the base AMI?"
end
unless File.exist?(default_ruby_path)
  raise "Cannot find default ruby build at #{default_ruby_path.inspect} -- was it created in the base AMI?"
end
unless File.exist?(default_ruby_path + '/bin/ruby')
  raise "Cannot find default ruby executable at #{default_ruby_path + '/bin/ruby'} -- was it created in the base AMI?"
end

# TODO: remove default_ruby_path and just rely on rbenv
file '/etc/environment' do
  content <<-EOM
# Dropped off by chef
# This is a static file (not script) used by PAM to set env variables.
RBENV_ROOT=#{rbenv_root}
PATH="/opt/chef/bin:#{rbenv_root}/shims:#{default_ruby_path}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"

RAILS_ENV=production
  EOM
end

# install dependencies
package 'libpq-dev'
package 'libsasl2-dev'
package 'ruby-dev'
