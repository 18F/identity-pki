execute "mount -o remount,exec,nosuid,nodev /tmp"

# create dir for AWS PostgreSQL combined CA cert bundle
directory '/usr/local/share/aws' do
  owner 'root'
  group 'root'
  mode 0755
  recursive true
end

# add AWS PostgreSQL combined CA cert bundle
remote_file '/usr/local/share/aws/rds-combined-ca-bundle.pem' do
  action :create
  group 'root'
  mode 0755
  owner 'root'
  sensitive true # nothing sensitive but using to remove unnecessary output
  source 'https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem'
end

app_name = 'sp-oidc-sinatra'

dhparam = ConfigLoader.load_config(node, "dhparam")

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

# setup required directories with system_user as the owner/group
%w{cached-copy config log}.each do |dir|
  directory "#{base_dir}/shared/#{dir}" do
    group node['login_dot_gov']['system_user']
    owner node.fetch(:passenger).fetch(:production).fetch(:user)
    recursive true
    subscribes :create, "deploy[/srv/#{app_name}]", :before
  end
end

ruby_bin_dir = "/opt/ruby_build/builds/#{node.fetch('login_dot_gov').fetch('ruby_version')}/bin"
ruby_build_path = [
  ruby_bin_dir,
  ENV.fetch('PATH'),
].join(':')

deploy_script_environment = {
  'PATH' => ruby_build_path,
  'RACK_ENV' => 'production',
  'HOME' => nil,
}

deploy "/srv/#{app_name}" do
  action :deploy
  before_symlink do
    cmd = "/opt/ruby_build/builds/#{node['login_dot_gov']['ruby_version']}/bin/bundle install --deployment --jobs 3 --path /srv/#{app_name}/shared/bundle --without deploy development test"
    execute cmd do
      cwd release_path
      #user 'ubuntu'
    end

    execute 'deploy activate step' do
      cwd release_path
      command './deploy/activate'
      user 'root'
      group 'root'
      environment(deploy_script_environment)
    end
  end

  repo 'https://github.com/18F/identity-openidconnect-sinatra.git'
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

basic_auth_enabled = !!ConfigLoader.load_config_or_nil(node, "basic_auth_user_name")

if basic_auth_enabled
  basic_auth_config 'generate basic auth config' do
    password ConfigLoader.load_config(node, "basic_auth_password")
    user_name ConfigLoader.load_config(node, "basic_auth_user_name")
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
    security_group_exceptions: ConfigLoader.load_config(node, "security_group_exceptions"),
    server_name: "#{app_name}.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}"
  })
end

directory "#{deploy_dir}/api" do
  owner node['login_dot_gov']['user']
  recursive true
  action :create
end

login_dot_gov_deploy_info "#{deploy_dir}/api/deploy.json" do
  owner node['login_dot_gov']['user']
  branch branch_name
end

execute "mount -o remount,noexec,nosuid,nodev /tmp"
