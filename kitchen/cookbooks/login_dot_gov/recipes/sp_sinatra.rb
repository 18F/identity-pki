execute "mount -o remount,exec,nosuid,nodev /tmp"

login_dot_gov_lets_encrypt 'sp-sinatra'

encrypted_config = Chef::EncryptedDataBagItem.load('config', 'app')["#{node.chef_environment}"]

base_dir = '/srv/sp-sinatra'

%w{config log}.each do |dir|
  directory "#{base_dir}/shared/#{dir}" do
    group node['login_dot_gov']['system_user']
    owner node['login_dot_gov']['system_user']
    recursive true
  end
end

execute "chown -R #{node['login_dot_gov']['system_user']}: #{base_dir}"
execute "chown -R #{node['login_dot_gov']['system_user']}: /opt/ruby_build"
execute "chown -R #{node['login_dot_gov']['system_user']}: /usr/local/src"

deploy '/srv/sp-sinatra' do
  action :deploy
  before_symlink do
    cmd = "/opt/ruby_build/builds/2.3.1/bin/bundle install --deployment --jobs 3 --path /srv/sp-sinatra/shared/bundle --without deploy development test"
    execute cmd do
      cwd release_path
      user 'ubuntu'
    end
  end
  repo 'https://github.com/18F/identity-sp-sinatra.git'
  symlinks ({
    "system" => "public/system",
    "pids" => "tmp/pids",
    "log" => "log",
    'bundle' => '.bundle'
  })
  user 'ubuntu'
end

file '/opt/nginx/conf/htpasswd' do
  content encrypted_config['http_basic_auth']
  notifies :restart, "service[passenger]"
end

# add nginx conf for app server
# TODO: JJG convert security_group_exceptions to hash so we can keep a note in both chef and nginx
#       configs as to why we added the exception.
template "/opt/nginx/conf/sites.d/sp-sinatra.login.gov.conf" do
  owner node['login_dot_gov']['system_user']
  notifies :restart, "service[passenger]"
  source 'nginx_server.conf.erb'
  variables({
    app: 'sp-sinatra',
    domain: "#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}",
    elb_cidr: node['login_dot_gov']['elb_cidr'],
    security_group_exceptions: encrypted_config['security_group_exceptions']
  })
end

execute "mount -o remount,noexec,nosuid,nodev /tmp"
