property :name, String, default: 'idp'

action :create do
  execute "mount -o remount,nosuid,nodev /tmp"

  # install apt dependencies
  ['libexpat1-dev',
   'libpython-dev',
   'libpython2.7-dev',
   'python-setuptools',
   'python2.7-dev'].each { |pkg| package pkg }

  # download letsencrypt CLI
  # TODO: JJG it may be a good idea to lock this down to a version number for
  # better compatibility/stability across provisions
  remote_file '/usr/local/src/certbot-auto' do
    mode 600
    sensitive true # nothing sensitive but using to remove unnecessary output
    source 'https://dl.eff.org/certbot-auto'
  end

  case name
  when 'idp'
    server_name = "#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}"
    server_alias = node.chef_environment == 'prod' ? 'secure.login.gov' : "idp.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}"
  when 'sp-rails'
    server_name = "sp.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}"
    server_alias = "#{name}.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}"
  else
    server_name = "#{name}.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}"
  end

  # TODO: Investigate why this fails to work when requesting this resource more than once.
  # service "passenger" do
  #   action :stop
  # end
  # This works instead:
  execute "service passenger stop"

  cmd = "./certbot-auto certonly -n "\
        "--standalone "\
        "--agree-tos "\
        "--email #{node['login_dot_gov']['admin_email']} "\
        "-d #{server_name} #{'-d ' + server_alias if server_alias}"

  cmd += ' --server https://acme-staging.api.letsencrypt.org/directory' unless node['login_dot_gov']['live_certs']

  # generate certs with LetsEncrypt on first run
  # set XDG_DATA_HOME env var since /tmp is a noexec mount
  # TODO: JJG move to official LE cookbook
  execute cmd do
    cwd '/usr/local/src'
    environment ({ 'XDG_DATA_HOME' => '/usr/local/src' })
    not_if { ::Dir.exist?("/etc/letsencrypt/live/#{server_name}") || ::Dir.exist?("/etc/letsencrypt/live/#{server_alias}") }
    notifies :stop, "service[passenger]", :before
  end

  # check if cert needs to be renewed if cert folder exists
  execute "./certbot-auto renew -n" do
    cwd '/usr/local/src'
    environment ({ 'XDG_DATA_HOME' => '/usr/local/src' })
    only_if { ::Dir.exist?("/etc/letsencrypt/live/#{server_name}") || ::Dir.exist?("/etc/letsencrypt/live/#{server_alias}") }
    notifies :stop, "service[passenger]", :before
    retries 3
  end

  dhparam = Chef::EncryptedDataBagItem.load('config', 'app')["#{node.chef_environment}"]["dhparam"]

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

  service "passenger" do
    action :start
  end

  execute "mount -o remount,noexec,nosuid,nodev /tmp"
end
