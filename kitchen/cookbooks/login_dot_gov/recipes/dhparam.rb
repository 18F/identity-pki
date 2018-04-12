
dhparam = ConfigLoader.load_config(node, "dhparam")

# generate a stronger DHE parameter on first run
# see: https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html#Forward_Secrecy_&_Diffie_Hellman_Ephemeral_Parameters
execute 'generate dhparam' do
  command %W[#{node.fetch('login_dot_gov').fetch('openssl').fetch('binary')} dhparam -out /etc/ssl/cert/dhparam.pem 4096]
  creates '/etc/ssl/certs/dhparam.pem'
  notifies :stop, "service[passenger]", :before
  only_if { dhparam.nil? }
end

file '/etc/ssl/certs/dhparam.pem' do
  content dhparam
  not_if { dhparam.nil? }
  sensitive true # noisy, not actually secret
end
