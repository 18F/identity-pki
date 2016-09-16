property :name, String, default: 'idp'

action :create do
  execute "mount -o remount,nosuid,nodev /tmp"

  # download letsencrypt CLI
  # TODO: JJG it may be a good idea to lock this down to a version number for
  # better compatibility/stability across provisions
  remote_file '/usr/local/src/certbot-auto' do
    mode 600
    source 'https://dl.eff.org/certbot-auto'
  end

  fqdn = "#{name}.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}"

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
        "-d #{fqdn}"

  cmd += ' --server https://acme-staging.api.letsencrypt.org/directory' unless node['login_dot_gov']['live_certs']

  # generate certs with LetsEncrypt on first run
  # set XDG_DATA_HOME env var since /tmp is a noexec mount
  # TODO: JJG move to official LE cookbook
  execute cmd do
    cwd '/usr/local/src'
    environment ({ 'XDG_DATA_HOME' => '/usr/local/src' })
    not_if { ::Dir.exist?("/etc/letsencrypt/live/#{fqdn}") }
    notifies :stop, "service[passenger]", :before
  end

  # check if cert needs to be renewed if cert folder exists
  execute "./certbot-auto renew" do
    cwd '/usr/local/src'
    environment ({ 'XDG_DATA_HOME' => '/usr/local/src' })
    only_if { ::Dir.exist?("/etc/letsencrypt/live/#{fqdn}") }
    notifies :stop, "service[passenger]", :before
  end

  dhparam = Chef::EncryptedDataBagItem.load('config', 'app')["#{node.chef_environment}"]["dhparam"]

  # generate a stronger DHE parameter on first run
  # see: https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html#Forward_Secrecy_&_Diffie_Hellman_Ephemeral_Parameters
  execute "openssl dhparam -out dhparam.pem 4096" do
    creates '/etc/ssl/certs/dhparam.pem' 
    cwd '/etc/ssl/certs'
    notifies :stop, "service[passenger]", :before
    only_if { dhparam == nil }
  end

  file '/etc/ssl/certs/dhparam.pem' do
    content dhparam
    not_if { dhparam == nil }
  end

  service "passenger" do
    action :start
  end

  execute "mount -o remount,noexec,nosuid,nodev /tmp"
end
