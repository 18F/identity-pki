execute "mount -o remount,exec,nosuid,nodev /tmp"

app_name = 'dashboard'
login_dot_gov_lets_encrypt app_name

encrypted_config = Chef::EncryptedDataBagItem.load('config', 'app')["#{node.chef_environment}"]

base_dir = '/srv/dashboard'
deploy_dir = "#{base_dir}/current/public"

# branch is 'master'(default) when env is dev, otherwise use stages/env 
branch_name = (node.chef_environment == 'dev' ? node['login_dot_gov']['branch_name'] : "stages/#{node.chef_environment}")
sha_env = (node.chef_environment == 'dev' ? node['login_dot_gov']['branch_name'] : "deploy")

%w{cached-copy config log}.each do |dir|
  directory "#{base_dir}/shared/#{dir}" do
    group node['login_dot_gov']['system_user']
    owner node['login_dot_gov']['system_user']
    recursive true
    subscribes :create, "deploy[/srv/dashboard]", :before
  end
end

execute "chown -R #{node['login_dot_gov']['system_user']} /home/#{node['login_dot_gov']['system_user']}/.bundle" do
  only_if { ::Dir.exist?("/home/#{node['login_dot_gov']['system_user']}/.bundle") }
  subscribes :run, "execute[/opt/ruby_build/builds/#{node['login_dot_gov']['ruby_version']}/bin/bundle install --deployment --jobs 3 --path /srv/dashboard/shared/bundle --without deploy development test]", :immediately
  subscribes :run, "execute[/opt/ruby_build/builds/#{node['login_dot_gov']['ruby_version']}/bin/bundle install --deployment --jobs 3 --path /srv/sp-rails/shared/bundle --without deploy development test]", :immediately
  subscribes :run, "execute[/opt/ruby_build/builds/#{node['login_dot_gov']['ruby_version']}/bin/bundle install --deployment --jobs 3 --path /srv/sp-sinatra/shared/bundle --without deploy development test]", :immediately
end
execute "chown -R #{node['login_dot_gov']['system_user']} /usr/local/src"
execute "chown -R #{node['login_dot_gov']['system_user']} /opt/ruby_build"
execute "chown -R #{node['login_dot_gov']['system_user']} /var/chef/cache"

template "#{base_dir}/shared/config/database.yml" do
  owner node['login_dot_gov']['system_user']
  sensitive true
  variables({
      database: 'dashboard',
      username: encrypted_config['db_username_app'],
      host: encrypted_config['db_host_app'],
      password: encrypted_config['db_password_app']
  })
end

deploy "#{base_dir}" do
  action :deploy

  before_symlink do
    execute "cp #{base_dir}/shared/config/application.yml #{release_path}/config/application.yml"
    # cp generated configs from chef to the shared dir on first run
    app_config = "#{base_dir}/shared/config/secrets.yml"
    unless File.exist?(app_config) && File.symlink?(app_config) || node['login_dot_gov']['setup_only']
      execute "cp #{release_path}/config/newrelic.yml #{base_dir}/shared/config"
      execute "cp #{release_path}/config/saml.yml #{base_dir}/shared/config"
      execute "cp #{release_path}/config/secrets.yml #{base_dir}/shared/config"
    end
    
    bundle = "/opt/ruby_build/builds/#{node['login_dot_gov']['ruby_version']}/bin/bundle install --deployment --jobs 3 --path #{base_dir}/shared/bundle --without deploy development test"
    assets = "/opt/ruby_build/builds/#{node['login_dot_gov']['ruby_version']}/bin/bundle exec rake assets:precompile"

    [bundle, assets].each do |cmd|
      execute cmd do
        cwd release_path
        environment ({
          'RAILS_ENV' => 'production',
          'DASHBOARD_SECRET_KEY_BASE'=> encrypted_config['secret_key_base_dashboard'],
          'SMTP_ADDRESS' => encrypted_config['smtp_settings']['address'],
          'SMTP_DOMAIN' => node['set_fqdn'],
          'SMTP_PASSWORD' => encrypted_config['smtp_settings']['password'],
          'SMTP_USERNAME' => encrypted_config['smtp_settings']['user_name'],
        })
        user node['login_dot_gov']['system_user']
      end
    end
  end

  repo 'https://github.com/18F/identity-dashboard.git'
  branch branch_name
  shallow_clone true
  keep_releases 1
  
  symlinks ({
    'vendor/bundle' => 'vendor/bundle',
    'config/database.yml' => 'config/database.yml',
    'config/newrelic.yml' => 'config/newrelic.yml',
    'config/saml.yml' => 'config/saml.yml',
    'config/application.yml' => 'config/application.yml',
    "log" => "log",
    "public/system" => "public/system",
    "tmp/pids" => "tmp/pids"
  })

  user 'ubuntu'
end

execute "/opt/ruby_build/builds/#{node['login_dot_gov']['ruby_version']}/bin/bundle exec rake db:create --trace" do
  cwd "#{base_dir}/current"
  environment({
    'RAILS_ENV' => "production"
  })
end

basic_auth_config 'generate basic auth config' do
  password encrypted_config['basic_auth_password']
  user_name encrypted_config["basic_auth_user_name"]
end

# add nginx conf for app server
# TODO: JJG convert security_group_exceptions to hash so we can keep a note in both chef and nginx
#       configs as to why we added the exception.
template "/opt/nginx/conf/sites.d/dashboard.login.gov.conf" do
  owner node['login_dot_gov']['system_user']
  notifies :restart, "service[passenger]"
  source 'nginx_server.conf.erb'
  variables({
    app: app_name,
    domain: "#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}",
    elb_cidr: node['login_dot_gov']['elb_cidr'],
    security_group_exceptions: encrypted_config['security_group_exceptions'],
    server_name: "#{app_name}.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}"
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

# set ownership back to ubuntu:nogroup
execute "chown -R #{node['login_dot_gov']['system_user']}:nogroup #{base_dir}"

execute "mount -o remount,noexec,nosuid,nodev /tmp"

# allow other execute permissions on all directories within the application folder
# https://www.phusionpassenger.com/library/admin/nginx/troubleshooting/ruby/#upon-accessing-the-web-app-nginx-reports-a-permission-denied-error
execute "chmod o+x -R /srv"
