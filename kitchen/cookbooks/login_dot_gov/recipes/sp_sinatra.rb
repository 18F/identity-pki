execute "mount -o remount,exec,nosuid,nodev /tmp"

# setup postgres root config resource
psql_config 'configure postgres root cert'


app_name = 'sp-sinatra'

dhparam = ConfigLoader.load_config(node, "dhparam")

basic_auth_username = ConfigLoader.load_config_or_nil(node, "basic_auth_user_name")
basic_auth_password = ConfigLoader.load_config_or_nil(node, "basic_auth_password")

# generate a stronger DHE parameter on first run
# see: https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html#Forward_Secrecy_&_Diffie_Hellman_Ephemeral_Parameters
execute "openssl dhparam -out dhparam.pem 4096" do
  creates '/etc/ssl/certs/dhparam.pem'
  cwd '/etc/ssl/certs'
  notifies :stop, "service[passenger]", :before
  only_if { dhparam == nil }
  sensitive true
end

file '/etc/ssl/certs/dhparam.pem' do
  content dhparam
  not_if { dhparam == nil }
  sensitive true
end

base_dir = "/srv/#{app_name}"
deploy_dir = "#{base_dir}/current/public"

branch_name = node.fetch('login_dot_gov').fetch('branch_name', "stages/#{node.chef_environment}")
sha_env = "deploy"

%w{cached-copy config log}.each do |dir|
  directory "#{base_dir}/shared/#{dir}" do
    group node['login_dot_gov']['system_user']
    owner node.fetch(:passenger).fetch(:production).fetch(:user)
    recursive true
    subscribes :create, "deploy[/srv/#{app_name}]", :before
  end
end

deploy "/srv/#{app_name}" do
  action :deploy
  before_symlink do
    cmd = "/opt/ruby_build/builds/#{node['login_dot_gov']['ruby_version']}/bin/bundle install --deployment --jobs 3 --path /srv/#{app_name}/shared/bundle --without deploy development test"
    execute cmd do
      cwd release_path
      #user 'ubuntu'
    end
  end
  
  repo "https://github.com/18F/identity-#{app_name}.git"
  branch branch_name
  shallow_clone true
  keep_releases 1

  symlinks ({
    "system" => "public/system",
    "pids" => "tmp/pids",
    "log" => "log",
    'bundle' => '.bundle'
  })
  #user 'ubuntu'
end

if basic_auth_username
  basic_auth_config 'generate basic auth config' do
    password  basic_auth_password
    user_name basic_auth_username
  end
end

# add nginx conf for app server
# TODO: JJG convert security_group_exceptions to hash so we can keep a note in both chef and nginx
#       configs as to why we added the exception.
template "/opt/nginx/conf/sites.d/#{app_name}.login.gov.conf" do
  owner node['login_dot_gov']['system_user']
  notifies :restart, "service[passenger]"
  source 'nginx_server.conf.erb'
  variables({
    app: app_name,
    domain: "#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}",
    elb_cidr: node['login_dot_gov']['elb_cidr'],
    saml_env: node.chef_environment,
    secret_key_base: ConfigLoader.load_config(node, "secret_key_base_rails"),
    security_group_exceptions: ConfigLoader.load_config(node, "security_group_exceptions"),
    server_name: "#{app_name}.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}",
  })
end

ruby_block 'extract_sha_of_revision' do
  block do
    Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
    release_dir = ::Dir.glob("#{base_dir}/releases/" + '201*')[0]
    
    # Dynamically set the file resource's attribute
    # Obtain the desired resource from resource_collection
    template_r = run_context.resource_collection.find(template: "#{deploy_dir}/api/deploy.json")
    # Update the content attribute
    template_r.variables ({
      env: node.chef_environment,
      branch: branch_name,
      user: 'chef',
      sha: ::File.read("#{::Dir.glob("#{base_dir}/releases/" + '201*')[0]}/.git/refs/heads/#{sha_env}").chomp,
      timestamp: release_dir.split('/').last
    })
  end
  action :run
end

directory "#{deploy_dir}/api" do
  owner node['login_dot_gov']['user']
  recursive true
  action :create
end

template "#{deploy_dir}/api/deploy.json" do
  owner node['login_dot_gov']['user']
  source 'deploy.json.erb'
end

execute "mount -o remount,noexec,nosuid,nodev /tmp"
