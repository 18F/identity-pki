case node[:platform_version]
when '16.04'
  package 'python-pip'
  execute 'install certbot via pip' do
    command 'pip install certbot certbot_dns_route53'
    not_if 'pip show certbot && pip show certbot_dns_route53'
  end
when '18.04'
    package 'certbot'
    package 'python3-pip'
    execute 'install certbot_dns_route53' do
      command 'pip3 install certbot_dns_route53==0.23.0'  #match certbot version from ubuntu
    end
else
  raise "Unexpected platform_version: #{node[:platform_version].inspect}"
end

include_recipe 'identity-pivcac::update_letsencrypt_certs'

base_dir	= "/srv/pki-rails"
deploy_dir	= "#{base_dir}/current/public"
shared_path	= "#{base_dir}/shared"
production_user	= node.fetch(:identity_shared_attributes).fetch(:production_user)
system_user	= node.fetch(:identity_shared_attributes).fetch(:system_user)

directory shared_path do
  owner system_user
  group system_user
  recursive true
end

# deploy_branch defaults to stages/<env>
# unless deploy_branch.identity-#{app_name} is specifically set otherwise
default_branch = node.fetch('login_dot_gov').fetch('deploy_branch_default')
deploy_branch = node.fetch('login_dot_gov').fetch('deploy_branch').fetch("identity-#{app_name}", default_branch)

# TODO: stop using deprecated deploy resource
deploy "#{base_dir}" do
  action :deploy

  user system_user

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
      group system_user
      owner production_user
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
    group system_user
    owner production_user
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
    owner system_user
    group production_user
    mode '0775'
    recursive true
  end
end

execute "rbenv exec bundle exec rake db:create db:migrate --trace" do
  cwd "#{base_dir}/current"
  environment({
    'RAILS_ENV' => "production"
  })
  user system_user
end

# ensure application.yml is readable by web user
file '/srv/pki-rails/current/config/application.yml' do
  group production_user
end

execute "chown -R #{production_user} #{shared_path}/log"

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
  user production_user
  command update_revocations_with_lock
end
