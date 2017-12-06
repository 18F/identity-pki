# Cookbook Name:: login_dot_gov
# Recipe:: static_eip
#
# Recipe to automatically associate an instance with a static IP at startup
# time using the aws-ec2-assign-elastic-ip python library.

# Do auto EIP assignment if this is an auto scaled instance whose role is
# listed in the auto_eip_enabled_roles list.
auto_eip_enabled = false
if node['provisioner'] && node.fetch('provisioner').fetch('auto-scaled')

  # we need to know our primary role in order to look up role-specific
  # valid_ips config
  role = File.read('/etc/login.gov/info/role').chomp

  # check whether static EIPs are enabled for this role
  if node.fetch('login_dot_gov').fetch('auto_eip_enabled_roles').include?(role)
    auto_eip_enabled = true
  end
end

if auto_eip_enabled
  Chef::Log.info('Static EIP assignment is enabled')

  package 'python'
  package 'awscli'
  package 'python-netaddr'

  sentinel_file = '/etc/login.gov/assigned-eip'

  # This script helps show the current EIP. It's not super useful otherwise.
  cookbook_file '/usr/local/bin/get-current-eips' do
    source 'get-current-eips'
    owner 'root'
    group 'root'
    mode '0755'
  end

  # This script is pretty much a drop-in replacement for
  # aws-ec2-assign-elastic-ip due to the EIP race condition assignment boto bug
  # https://github.com/skymill/aws-ec2-assign-elastic-ip/pull/25
  cookbook_file '/usr/local/bin/aws-grab-static-eip' do
    source 'aws-grab-static-eip'
    owner 'root'
    group 'root'
    mode '0755'
  end

  # auto_eip_config.json is a JSON blob in citadel. Expected example structure:
  #
  # {
  #   "worker": {
  #     "valid_ips": "192.0.2.128/25,192.0.2.5",
  #     "invalid_ips": null
  #   },
  #   "jumphost": {
  #     "valid_ips": "192.0.2.7,192.0.2.8",
  #     "invalid_ips": "192.0.2.5"
  #   }
  # }
  #
  # The valid_ips and invalid_ips strings will be passed directly to
  # aws-ec2-assign-elastic-ip.
  #
  # After you allocate an EIP, be sure to add it to the tracking Google doc in
  # addition to the S3 config.
  auto_eip_config = ConfigLoader.load_json(node, 'auto_eip_config.json')

  role_config = auto_eip_config.fetch(role)

  # require valid_ips to be present, allow invalid_ips to be absent
  valid_ips = role_config.fetch('valid_ips')
  invalid_ips = role_config['invalid_ips']

  raise 'valid_ips must be set in auto_eip_config.json' unless valid_ips

  assign_opts = ['--valid-ips', valid_ips]
  assign_opts += ['--invalid-ips', invalid_ips] if invalid_ips

  execute 'assign eips' do
    command ['aws-grab-static-eip'] + assign_opts
    notifies :run, 'execute[sleep after eip assignment]', :immediately
    not_if { File.exist?(sentinel_file) }
    live_stream true

    # Retry assignment a few times. We can fail the first time if we hit the
    # race condition where another instance grabs the same EIP we are
    # attempting to grab.
    retries 4
    retry_delay 5
  end

  # sleep after assigning an EIP so that we don't attempt to do stuff involving
  # the network during the cutover
  execute 'sleep after eip assignment' do
    command "touch '#{sentinel_file}' && sleep 20"
    action :nothing
  end

else
  Chef::Log.info('Static EIP assignment not enabled')
end
