package 'python-pip'
execute 'install certbot via pip' do
  command 'pip install certbot certbot_dns_route53'
  not_if 'pip show certbot && pip show certbot_dns_route53'
end

include_recipe 'identity-pivcac::update_letsencrypt_certs'

base_dir	= "/srv/pki-rails"
deploy_dir	= "#{base_dir}/current/public"
shared_path	= "#{base_dir}/shared"

include_recipe 'login_dot_gov::dhparam'

directory shared_path do
  owner node['login_dot_gov']['system_user']
  group node['login_dot_gov']['system_user']
  recursive true
end

branch_name = node.fetch('login_dot_gov').fetch('branch_name', "stages/#{node.chef_environment}")

deploy "#{base_dir}" do
  action :deploy

  user node.fetch('login_dot_gov').fetch('system_user')

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
      owner node.fetch(:passenger).fetch(:production).fetch(:user)
      recursive true
    end

    # Cryptographically speaking, these certs are public. However, we do not yet
    # have permission from DoD to check the collection into the repo.
    file "#{release_path}/config/certs/all_certs_deploy.pem" do
      content ConfigLoader.load_config(node, 'all_certs_deploy.pem')
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
  branch branch_name
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
    passenger_ruby: lazy { Dir.chdir(deploy_dir) { shell_out!(%w{rbenv which ruby}).stdout.chomp } },
    server_name: node.fetch('pivcac').fetch('wildcard'),
    ssl_domain: node.fetch('pivcac').fetch('domain')
  })

end

%w{config log}.each do |dir|
  directory "#{base_dir}/shared/#{dir}" do
    group node['login_dot_gov']['system_user']
    owner node.fetch(:passenger).fetch(:production).fetch(:user)
    recursive true
    subscribes :create, "deploy[/srv/pki-rails]", :before
  end
end

web_writable_dirs = [
  'log',
  'tmp/cache',
  'tmp/pids',
  'tmp/sockets',
]

web_writable_dirs.each do |dir|
  directory "#{shared_path}/#{dir}" do
    owner node.fetch('login_dot_gov').fetch('system_user')
    group node.fetch('login_dot_gov').fetch('web_system_user')
    mode '0775'
    recursive true
  end
end

execute "rbenv exec bundle exec rake db:create db:migrate --trace" do
  cwd "#{base_dir}/current"
  environment({
    'RAILS_ENV' => "production"
  })
  user node['login_dot_gov']['system_user']
end

# ensure application.yml is readable by web user
file '/srv/pki-rails/current/config/application.yml' do
  group node.fetch('login_dot_gov').fetch('web_system_user')
end

execute "chown -R #{node[:passenger][:production][:user]} #{shared_path}/log"

cron_d 'update_cert_revocations' do
  hour '*/4'
  user node.fetch('login_dot_gov').fetch('web_system_user')
  # if random_delay is ever implemented properly we can lose the "sleep"
  command "sleep $[ ( $RANDOM % 3600 ) + 1 ]s && cd #{base_dir}/current && rake crls:update 2>&1 >> #{shared_path}/log/cron.log"
end
