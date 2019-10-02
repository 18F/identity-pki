# setup postgres root config resource
psql_config 'configure postgres root cert'


app_name = 'sp-sinatra'

basic_auth_username = ConfigLoader.load_config_or_nil(node, "basic_auth_user_name")
basic_auth_password = ConfigLoader.load_config_or_nil(node, "basic_auth_password")

include_recipe 'login_dot_gov::dhparam'

base_dir = "/srv/#{app_name}"
deploy_dir = "#{base_dir}/current/public"

branch_name = node.fetch('login_dot_gov').fetch('branch_name', "stages/#{node.chef_environment}")

%w{cached-copy config log}.each do |dir|
  directory "#{base_dir}/shared/#{dir}" do
    owner node.fetch(:passenger).fetch(:production).fetch(:user)
    group node['login_dot_gov']['system_user']
    recursive true
    subscribes :create, "deploy[/srv/#{app_name}]", :before
  end
end

# TODO: stop using deprecated deploy resource
deploy "/srv/#{app_name}" do
  action :deploy
  before_symlink do
    cmd = "rbenv exec bundle install --deployment --jobs 3 --path /srv/#{app_name}/shared/bundle --without deploy development test"
    execute cmd do
      cwd release_path
      #user 'ubuntu'
    end
  end

  repo "https://github.com/18F/identity-#{app_name}.git"
  branch branch_name
  shallow_clone true
  keep_releases 1

  symlinks({
    "log" => "log",
  })

  # user node['login_dot_gov']['system_user']
end

if basic_auth_username
  basic_auth_config 'generate basic auth config' do
    password  basic_auth_password
    user_name basic_auth_username
  end
end

# set log directory permissions
directory "#{base_dir}/shared/log" do
    owner node.fetch('login_dot_gov').fetch('web_system_user')
    group node.fetch('login_dot_gov').fetch('web_system_user')
    mode '0775'
    recursive true
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
    passenger_ruby: lazy { Dir.chdir(deploy_dir) { shell_out!(%w{rbenv which ruby}).stdout.chomp } },
    security_group_exceptions: ConfigLoader.load_config(node, "security_group_exceptions"),
    server_name: "#{app_name}.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}",
  })
end

directory "#{deploy_dir}/api" do
  owner node.fetch('login_dot_gov').fetch('system_user')
  recursive true
  action :create
end

login_dot_gov_deploy_info "#{deploy_dir}/api/deploy.json" do
  owner node.fetch('login_dot_gov').fetch('system_user')
  branch branch_name
end
