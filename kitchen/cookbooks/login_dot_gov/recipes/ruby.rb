# This should not be happening, and should be fixed as part of
# https://github.com/18F/identity-devops-private/issues/230
#
# Here's the sequence of things that are happening here, from the result
# backwards:
# 1. The idp worker is running as a sidekiq task
# 2. This task is configured to run as the ubuntu user
# 3. This task also explicitly sources `/home/ubuntu/.bash_profile`
# 4. This file contains environment variables consumed by the worker
# 5. This file is an ERB template
# 6. The variables in this template are passed in by chef
# 7. These come from ruby variables and string templates
# 8. The basic_auth_* variables should not be set in staging or prod
# 9. The configloader downloads these secrets from s3 as individual files
# 10. These were previously set to zero byte files as placeholders
# 11. These now don't exist in s3 for staging and prod since they are unused
# 12. The config loader as sanity checks for file existence in prod
# 13. So we can't call the configloader on nonexistent files in prod
# 14. Setting them to the empty string at least replicates the previous behavior
# 15. Profit?!?
if node.chef_environment == 'prod'
  basic_auth_user_name = ""
  basic_auth_password = ""
else
  basic_auth_user_name = ConfigLoader.load_config_or_nil(node, "basic_auth_user_name")
  basic_auth_password = ConfigLoader.load_config_or_nil(node, "basic_auth_password")
end
# TODO: don't set anything in ~ubuntu/.bash_profile
template '/home/ubuntu/.bash_profile' do
  owner node['login_dot_gov']['system_user']
  mode '0644'
  sensitive true
  variables({
    idp_slo_url: "https://idp.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}/api/saml/logout2018",
    idp_sp_url: "https://#{basic_auth_user_name}:#{basic_auth_password}@idp.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}/api/service_provider",
    idp_sso_url: "https://idp.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}/api/saml/auth2018",
    sp_name: basic_auth_user_name,
    sp_pass: basic_auth_password
  })
  subscribes :run, 'execute[ruby-build install]', :delayed
end

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
