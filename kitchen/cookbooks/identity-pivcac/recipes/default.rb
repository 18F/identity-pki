snap_certbot_cmds = {
  'set http proxy':'snap set system proxy.http=http://obproxy.login.gov.internal:3128',
  'set https proxy':'snap set system proxy.https=http://obproxy.login.gov.internal:3128',
  'install certbot from snap':'snap install certbot --stable --classic',
  'trust route53 plugin':'snap set certbot trust-plugin-with-root=ok',
  'install certbot route53 plugin from snap':'snap install certbot-dns-route53 --stable --classic'
}

snap_certbot_cmds.each_pair do |cmd_name, cmd_exec|
  execute cmd_name do
    command cmd_exec
  end
end

include_recipe 'identity-pivcac::update_letsencrypt_certs'

base_dir    = "/srv/pki-rails"
deploy_dir  = "#{base_dir}/current/public"
shared_path = "#{base_dir}/shared"
app_name    = 'pivcac'

directory shared_path do
  owner node['login_dot_gov']['system_user']
  group node['login_dot_gov']['system_user']
  recursive true
end

# deploy_branch defaults to stages/<env>
# unless deploy_branch.identity-#{app_name} is specifically set otherwise
default_branch = node.fetch('login_dot_gov').fetch('deploy_branch_default')
deploy_branch  = node.fetch('login_dot_gov').fetch('deploy_branch').fetch("identity-#{app_name}", default_branch)

# TODO: stop using deprecated deploy resource
deploy "#{base_dir}" do
  action :deploy

  user node['login_dot_gov']['system_user']

  # Don't try to use database.yml in /shared.
  symlink_before_migrate({})

  before_symlink do
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

    directory "#{shared_path}/config/certs" do
      group node['login_dot_gov']['system_user']
      owner node['login_dot_gov']['web_system_user']
      recursive true
    end

    cmds = [
      "rbenv exec bundle install --deployment --jobs 3 --path #{base_dir}/shared/bundle --without deploy development test",
      "rbenv exec bundle exec bin/activate",
      # "rbenv exec bundle exec rake assets:precompile",
    ]

    cmds.each do |cmd|
      execute cmd do
        cwd release_path
        environment ({
          'RAILS_ENV' => 'production',
        })
      end
    end
  end

  repo 'https://github.com/18F/identity-pki.git'
  branch deploy_branch
  shallow_clone true
  keep_releases 1
  
  symlinks ({
    "log" => "log",
    "tmp/cache" => "tmp/cache",
    "tmp/pids" => "tmp/pids",
    "tmp/sockets" => "tmp/sockets",
  })

end

template "/opt/nginx/conf/sites.d/pivcac.conf" do
  notifies :restart, "service[passenger]"
  source 'nginx_server.conf.erb'
  variables({
    log_path: '/var/log/nginx',
    passenger_ruby: lazy { Dir.chdir(deploy_dir) { shell_out!(%w{rbenv which ruby}).stdout.chomp } },
    server_name: node.fetch('pivcac').fetch('wildcard'),
    ssl_domain: node.fetch('pivcac').fetch('domain')
  })
end

%w{config log}.each do |dir|
  directory "#{base_dir}/shared/#{dir}" do
    group node['login_dot_gov']['system_user']
    owner node['login_dot_gov']['web_system_user']
    recursive true
    subscribes :create, "deploy[#{base_dir}]", :before
  end
end

%w{cache pids sockets}.each do |dir|
  directory "#{shared_path}/tmp/#{dir}" do
    owner node['login_dot_gov']['system_user']
    group node['login_dot_gov']['web_system_user']
    mode '0775'
    recursive true
  end
end

execute "rbenv exec bundle exec rake db:create db:migrate:monitor_concurrent --trace" do
  cwd "#{base_dir}/current"
  environment({
    'RAILS_ENV' => "production"
  })
  user node['login_dot_gov']['system_user']
end

# ensure application.yml is readable by web user
file "#{base_dir}/current/config/application.yml" do
  group node['login_dot_gov']['web_system_user']
end

directory "#{deploy_dir}/api" do
  owner node['login_dot_gov']['system_user']
  recursive true
  action :create
end

login_dot_gov_deploy_info "#{deploy_dir}/api/deploy.json" do
  owner node['login_dot_gov']['system_user']
  branch deploy_branch
end

update_revocations_script = '/usr/local/bin/update_cert_revocations'
update_revocations_with_lock = "flock -n /tmp/update_cert_revocations.lock "\
                               "-c #{update_revocations_script}"

template update_revocations_script do
  source 'update_cert_revocations.erb'
  mode 0755
  variables({
    app_path: "#{base_dir}/current",
    log_file: "#{shared_path}/log/cron.log"
  })
end

cron_d 'update_cert_revocations' do
  hour '*/4'
  user node['login_dot_gov']['web_system_user']
  command update_revocations_with_lock
end

# set log directory permissions
directory "#{shared_path}/log" do
  owner node['login_dot_gov']['web_system_user']
  group node['login_dot_gov']['web_system_user']
  mode '0775'
  recursive true
end

# Fixes permissions and groups needed for passenger to actually run the application on the new hardened images
include_recipe 'login_dot_gov::fix_permissions'
