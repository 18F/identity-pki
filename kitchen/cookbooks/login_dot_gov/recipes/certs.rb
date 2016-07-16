ENV['TMPDIR'] = '/usr/local/src' # mv due to noexec on /tmp mountpoint

# download letsencrypt CLI
remote_file '/usr/local/src/certbot-auto' do
  mode 600
  source 'https://dl.eff.org/certbot-auto'
end

# add temporary conf for :80 server in nginx that overrides other configs and reload nginx
letsencrypt_conf = '/opt/nginx/conf/sites.d/ZZ-letsencrypt.gov.conf'

template letsencrypt_conf do
  source 'letsencrypt.conf.erb'
  owner node['login_dot_gov']['system_user']
  notifies :restart, "service[passenger]", :immediately
end

# remove temporary conf and reload nginx
file letsencrypt_conf do
  action :delete
end

# set machine name (ie. dev.login.gov) or empty array
letsencrypt_hostnames = ["dev-tf.#{node['login_dot_gov']['domain_name']}"]

# generate hostnames based on app names and add to array
node['login_dot_gov']['app_names'].each do |app|
  letsencrypt_hostnames << "#{app}-dev-tf.#{node['login_dot_gov']['domain_name']}"
end

# add or renew certs using letsencrypt certbot-auto script
cmd = "./certbot-auto certonly -n "\
      "--webroot -w '/opt/nginx/html/' "\
      "--agree-tos --email #{node['login_dot_gov']['admin_email']} "\
      "-d #{letsencrypt_hostnames.join(' -d ').to_s}"

# set XDG_DATA_HOME env var since /tmp is a noexec mount
execute cmd do
  cwd '/usr/local/src'
  environment ({ 'XDG_DATA_HOME' => '/usr/local/src' })
end
