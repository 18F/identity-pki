users_manage "#{node.chef_environment}" do
  action [:create]
  data_bag 'users'
  # identity-devops-private creates unix users on auto-scaled instances
  not_if { node.fetch('provisioner', {'auto-scaled' => false}).fetch('auto-scaled') }
end

# Not great to have divergence between kitchen tests and production systems,
# but we still use the ubuntu user to run kitchen-ec2, even though we don't use
# the ubuntu user anywhere else.
if !ENV['TEST_KITCHEN'] && node.fetch('provisioner', {'auto-scaled' => false}).fetch('auto-scaled')
  user 'ubuntu' do
    action :remove
  end
  group 'ubuntu' do
    action :remove
  end
  directory '/home/ubuntu' do
    action :delete
    recursive true
  end
end
