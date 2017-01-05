login_dot_gov_lets_encrypt 'idp'

encrypted_config = Chef::EncryptedDataBagItem.load('config', 'app')["#{node.chef_environment}"]

file '/opt/nginx/conf/htpasswd' do
  content encrypted_config['http_basic_auth']
  notifies :restart, "service[passenger]"
end

# branch is 'master'(default) when env is dev, otherwise use stages/env 
branch_name = (node.chef_environment == 'dev' ? node['login_dot_gov']['branch_name'] : "stages/#{node.chef_environment}")
base_dir = '/srv/idp'
deploy_dir = "#{base_dir}/current/public"

# add nginx conf for app server
# TODO: JJG convert security_group_exceptions to hash so we can keep a note in both chef and nginx
#       configs as to why we added the exception.
template "/opt/nginx/conf/sites.d/idp.login.gov.conf" do
  owner node['login_dot_gov']['system_user']
  notifies :restart, "service[passenger]"
  source 'nginx_server.conf.erb'
  variables({
    app: 'idp',
    domain: "#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}",
    elb_cidr: node['login_dot_gov']['elb_cidr'],
    security_group_exceptions: encrypted_config['security_group_exceptions']
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
  variables ({
    env: node.chef_environment,
    branch: branch_name,
    user: 'chef',
    sha: ::File.read("#{base_dir}/releases/chef/.git/refs/heads/#{branch_name}").chomp,
    timestamp: ::Time.new.strftime("%Y%m%d%H%M%S")
  })
end
