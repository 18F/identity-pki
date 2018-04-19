installers_dir = '/opt/aws/installers'

directory '/opt/aws'
directory installers_dir

remote_file "#{installers_dir}/cloudhsm-client-pkcs11_latest_amd64.deb" do
  source 'https://s3.amazonaws.com/cloudhsmv2-software/cloudhsm-client-pkcs11_latest_amd64.deb'
end

remote_file "#{installers_dir}/cloudhsm-client_latest_amd64.deb" do
  source 'https://s3.amazonaws.com/cloudhsmv2-software/cloudhsm-client_latest_amd64.deb'
end

dpkg_package 'cloudhsm-client' do
  source "#{installers_dir}/cloudhsm-client_latest_amd64.deb"
end

dpkg_package 'cloudhsm-client-pkcs11' do
  source "#{installers_dir}/cloudhsm-client-pkcs11_latest_amd64.deb"
end

apt_package 'libengine-pkcs11-openssl'

file '/opt/cloudhsm/etc/customerCA.crt' do
  content node.fetch('login_dot_gov').fetch('cloudhsm_customer_ca')
end

# TODO steps to fully configure cloudhsm client, or configure the cloudhsm
#   config files directly by populating IPs and such
# service cloudhsm-client stop
# /opt/cloudhsm/bin/configure -a <cloudhsm_instance_private_ip>
# service cloudhsm-client start
# possible sleep needed
# /opt/cloudhsm/bin/configure -m
#
