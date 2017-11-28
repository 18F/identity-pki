# Cookbook Name:: login_dot_gov
# Recipe:: static_eip
#
# Recipe to automatically associate an instance with a static IP at startup
# time using the aws-ec2-assign-elastic-ip python library.

if node.fetch('login_dot_gov').fetch('auto_eip_enabled')

  # auto_eip_config is a JSON blob in citadel that must contain strings
  # valid_ips and invalid_ips, which will be passed directly to
  # aws-ec2-assign-elastic-ip.
  auto_eip_config = ConfigLoader.load_json(node, 'auto_eip_config')

  package 'python-pip'

  valid_ips = auto_eip_config.fetch('valid_ips')
  invalid_ips = auto_eip_config.fetch('invalid_ips')

  # pip needs /tmp/ to be exec
  execute 'mount -o remount,exec /tmp'
  execute 'pip install aws-ec2-assign-elastic-ip' do
    umask '0022' # ensure
    not_if 'pip show aws-ec2-assign-elastic-ip'
  end
  execute 'mount -o remount,noexec /tmp'

  if !valid_ips && !invalid_ips
    raise 'At least valid_ips or invalid_ips must be set in auto_eip_config'
  end

  sentinel_file = '/etc/login.gov/assigned-eip'

  # temporary script due to aws-ec2-assign-elastic-ip race condition (#24)
  cookbook_file '/usr/local/bin/get-current-eips' do
    source 'get-current-eips'
    owner 'root'
    group 'root'
    mode '0755'
  end

  assign_opts = []

  assign_opts += ['--valid-ips', valid_ips] if valid_ips
  assign_opts += ['--invalid-ips', invalid_ips] if invalid_ips

  assign_cmd = ['aws-ec2-assign-elastic-ip'] + assign_opts

  execute 'assign eips' do
    command assign_cmd.join(' ') + ' && get-current-eips'
    notifies :run, 'execute[sleep after eip assignment]', :immediately
    not_if { File.exist?(sentinel_file) }
    live_stream true

    # retry due to aws-ec2-assign-elastic-ip race condition (#24)
    retries 3
    retry_delay 5
  end

  # sleep after assigning an EIP so that we don't attempt to do stuff involving
  # the network during the cutover
  execute 'sleep after eip assignment' do
    command "touch '#{sentinel_file}' && sleep 30"
    action :nothing
  end

end
