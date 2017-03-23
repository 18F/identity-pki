login_dot_gov_lets_encrypt 'idp'

encrypted_config = Chef::EncryptedDataBagItem.load('config', 'app')["#{node.chef_environment}"]

basic_auth_config 'generate basic auth config' do
  password encrypted_config['basic_auth_password']
  user_name encrypted_config["basic_auth_user_name"]
end

# branch is 'master'(default) when env is dev, otherwise use stages/env 
branch_name = (node.chef_environment == 'dev' ? node['login_dot_gov']['branch_name'] : "stages/#{node.chef_environment}")
base_dir = '/srv/idp'
deploy_dir = "#{base_dir}/current/public"

# add nginx conf for app server
# TODO: JJG convert security_group_exceptions to hash so we can keep a note in both chef and nginx
#       configs as to why we added the exception.
app_name = 'idp'

template "/opt/nginx/conf/sites.d/login.gov.conf" do
  owner node['login_dot_gov']['system_user']
  notifies :restart, "service[passenger]"
  source 'nginx_server.conf.erb'
  variables({
    app: app_name,
    domain: "#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}",
    elb_cidr: node['login_dot_gov']['elb_cidr'],
    security_group_exceptions: encrypted_config['security_group_exceptions'],
    server_aliases: "#{app_name}.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}",
    server_name: "#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}"
  })
end

directory "#{deploy_dir}/api" do
  owner node['login_dot_gov']['user']
  recursive true
  action :create
end

template "#{deploy_dir}/api/deploy.json" do
  owner node['login_dot_gov']['user']
  source 'deploy.json.erb'
  variables lazy { ({
    env: node.chef_environment,
    branch: branch_name,
    user: 'chef',
    sha: ::File.read("#{base_dir}/releases/chef/.git/refs/remotes/origin/#{branch_name}").chomp,
    timestamp: ::Time.new.strftime("%Y%m%d%H%M%S")
  })}
end

execute "/opt/ruby_build/builds/#{node['login_dot_gov']['ruby_version']}/bin/bundle exec whenever --update-crontab" do
  cwd "#{base_dir}/current"
  environment({
    'RAILS_ENV' => "production"
  })
  only_if { node.name == "idp1.0.#{node.chef_environment}" } # first idp host
end

# allow other execute permissions on all directories within the application folder
# https://www.phusionpassenger.com/library/admin/nginx/troubleshooting/ruby/#upon-accessing-the-web-app-nginx-reports-a-permission-denied-error
execute "chmod o+x -R /srv"
