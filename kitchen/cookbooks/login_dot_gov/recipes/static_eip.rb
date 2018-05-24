# Cookbook Name:: login_dot_gov
# Recipe:: static_eip
#
# Recipe to automatically associate an instance with a static IP at startup
# time using the static_eip cookbook.

# Do auto EIP assignment if this is an auto scaled instance whose role is
# listed in the auto_eip_enabled_roles list.
auto_eip_enabled = false
if node['provisioner'] && node.fetch('provisioner').fetch('auto-scaled')

  # we need to know our primary role in order to look up role-specific
  # valid_ips config
  primary_role = File.read('/etc/login.gov/info/role').chomp

  # check whether static EIPs are enabled for this role
  if node.fetch('login_dot_gov').fetch('auto_eip_enabled_roles').include?(primary_role)
    auto_eip_enabled = true
  end
end

if auto_eip_enabled
  Chef::Log.info('Static EIP assignment is enabled')

  static_eip_assign do
    role primary_role
    environment node.chef_environment
    sentinel_file '/etc/login.gov/assigned-eip'
    data_bag_name 'private'
    data_bag_item_name 'auto_eip_config'
  end
else
  Chef::Log.info('Static EIP assignment not enabled')
end
