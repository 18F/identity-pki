template '/home/ubuntu/.bash_profile' do
  owner node['login_dot_gov']['system_user']
  mode '0644'
  sensitive true
  variables({
    idp_slo_url: "https://idp.#{node.chef_environment}.login.gov/api/saml/logout",
    idp_sp_url: "https://#{ConfigLoader.load_config(node, "basic_auth_user_name")}:#{ConfigLoader.load_config(node, "basic_auth_password")}@idp.#{node.chef_environment}.login.gov/api/service_provider",
    idp_sso_url: "https://idp.#{node.chef_environment}.login.gov/api/saml/auth",
    sp_name: ConfigLoader.load_config(node, "basic_auth_user_name"),
    sp_pass: ConfigLoader.load_config(node, "basic_auth_password")
  })
  subscribes :run, 'execute[ruby-build install]', :delayed
end

# add to users path
template '/etc/environment' do
  source 'environment.erb'
  sensitive true
  variables({
    dashboard_log: "/srv/dashboard/log/shared/production.log",
    ruby_version: node['login_dot_gov']['ruby_version'],
    saml_env: node.chef_environment,
  })
  subscribes :run, 'execute[ruby-build install]', :delayed
end

# install dependencies
# TODO: JJG convert to platform agnostic way of installing packages to avoid case statement(s)
execute "apt-get update"

case
when platform_family?('rhel')
  ['cyrus-sasl-devel',
   'libtool-ltdl-devel',
   'postgresql-devel',
   'ruby-devel',
   'nodejs',
   'npm'].each { |pkg| package pkg }
when platform_family?('debian')
  ['libpq-dev',
   'libsasl2-dev',
   'ruby-dev',
   'nodejs',
   'npm'].each { |pkg| package pkg }
end

#execute 'source /etc/environment'

# install ruby
ruby_runtime node['login_dot_gov']['ruby_version'] do
  provider :ruby_build
end

execute "chown -R #{node['login_dot_gov']['system_user']}:adm /opt/ruby_build"
