execute "mount -o remount,exec,nosuid,nodev /tmp"

login_dot_gov_lets_encrypt 'dashboard'

encrypted_config = Chef::EncryptedDataBagItem.load('config', 'app')["#{node.chef_environment}"]

base_dir = '/srv/dashboard'
deploy_dir = "#{base_dir}/current/public"

# branch is 'master'(default) when env is dev, otherwise use stages/env 
branch_name = (node.chef_environment == 'dev' ? node['login_dot_gov']['branch_name'] : "stages/#{node.chef_environment}")
sha_env = (node.chef_environment == 'dev' ? node['login_dot_gov']['branch_name'] : "deploy")

%w{config log}.each do |dir|
  directory "#{base_dir}/shared/#{dir}" do
    group node['login_dot_gov']['system_user']
    owner node['login_dot_gov']['system_user']
    recursive true
  end
end

execute "chown -R #{node['login_dot_gov']['system_user']} #{base_dir}"
execute "chown -R #{node['login_dot_gov']['system_user']} /opt/ruby_build"
execute "chown -R #{node['login_dot_gov']['system_user']} /var/chef/cache"
execute "chown -R #{node['login_dot_gov']['system_user']} /home/ubuntu/.bundle /usr/local/src"

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
    bundle = "/opt/ruby_build/builds/2.3.3/bin/bundle install --deployment --jobs 3 --path #{base_dir}/shared/bundle --without deploy development test"
    assets = '/opt/ruby_build/builds/2.3.3/bin/bundle exec rake assets:precompile'

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
    "log" => "log",
    "public/system" => "public/system",
    "tmp/pids" => "tmp/pids"
  })

  user 'ubuntu'
end

execute '/opt/ruby_build/builds/2.3.3/bin/bundle exec rake db:create --trace' do
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
    app: 'dashboard',
    domain: "#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}",
    elb_cidr: node['login_dot_gov']['elb_cidr'],
    security_group_exceptions: encrypted_config['security_group_exceptions']
  })
end

ruby_block 'extract_sha_of_revision' do
  block do
    Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
    release_dir = ::Dir.glob("#{base_dir}/releases/" + '201*')[0]

    # Dynamically set the file resource's attribute
    # Obtain the desired resource from resource_collection
    template_r = run_context.resource_collection.find(template: "#{node['login_dot_gov']['release_dir']}/api/deploy.json")
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

directory "#{node['login_dot_gov']['release_dir']}/api" do
  owner node['login_dot_gov']['user']
  recursive true
  action :create
end

template "#{node['login_dot_gov']['release_dir']}/api/deploy.json" do
  owner node['login_dot_gov']['user']
  source 'deploy.json.erb'
end

execute "mount -o remount,noexec,nosuid,nodev /tmp"
