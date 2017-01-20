execute "mount -o remount,exec,nosuid,nodev /tmp"

login_dot_gov_lets_encrypt 'sp-rails'

encrypted_config = Chef::EncryptedDataBagItem.load('config', 'app')["#{node.chef_environment}"]

base_dir = '/srv/sp-rails'
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

template "#{base_dir}/shared/config/secrets.yml" do
  action :create
  source 'secrets.yml.erb'
  manage_symlink_source true
  sensitive true
  subscribes :create, 'resource[git]', :immediately
  user node['login_dot_gov']['system_user']

  variables({
    secret_key_base: encrypted_config['secret_key_base_rails'],
    saml_issuer: node['login_dot_gov']['sp_rails']['saml_issuer'],
    idp_sso_url: node['login_dot_gov']['sp_rails']['idp_sso_url'],
    idp_slo_url: node['login_dot_gov']['sp_rails']['idp_slo_url'],
    http_auth_username: node['login_dot_gov']['sp_rails']['http_auth_username'],
    http_auth_password: node['login_dot_gov']['sp_rails']['http_auth_password'],
    idp_cert_fingerprint: node['login_dot_gov']['sp_rails']['idp_cert_fingerprint']
  })
end

execute "chown -R #{node['login_dot_gov']['system_user']}:nogroup #{base_dir}"
execute "chown -R #{node['login_dot_gov']['system_user']} /opt/ruby_build"
execute "chown -R #{node['login_dot_gov']['system_user']} /usr/local/src"

template "#{base_dir}/shared/config/database.yml" do
  owner node['login_dot_gov']['system_user']
  sensitive true
  variables({
      database: 'sp_rails',
      username: encrypted_config['db_username_app'],
      host: encrypted_config['db_host_app'],
      password: encrypted_config['db_password_app']
  })
end

deploy '/srv/sp-rails' do
  action :deploy

  before_symlink do
    bundle = "/opt/ruby_build/builds/#{node['login_dot_gov']['ruby_version']}/bin/bundle install --deployment --jobs 3 --path #{base_dir}/shared/bundle --without deploy development test"
    assets = "/opt/ruby_build/builds/#{node['login_dot_gov']['ruby_version']}/bin/bundle exec rake assets:precompile"

    [bundle, assets].each do |cmd|
      execute cmd do
        cwd release_path
        user 'ubuntu'
      end
    end
  end

  repo 'https://github.com/18F/identity-sp-rails.git'
  branch_name
  shallow_clone true
  keep_releases 1

  symlinks ({
    'vendor/bundle' => 'vendor/bundle',
    'config/database.yml' => 'config/database.yml',
    'config/secrets.yml' => 'config/secrets.yml',
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
app_name = 'sp-rails'

template "/opt/nginx/conf/sites.d/sp-rails.login.gov.conf" do
  owner node['login_dot_gov']['system_user']
  notifies :restart, "service[passenger]"
  source 'nginx_server.conf.erb'
  variables({
    app: app_name,
    domain: "#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}",
    elb_cidr: node['login_dot_gov']['elb_cidr'],
    security_group_exceptions: encrypted_config['security_group_exceptions'],
    server_aliases: "#{app_name}.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}",
    server_name: "sp.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}"
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
