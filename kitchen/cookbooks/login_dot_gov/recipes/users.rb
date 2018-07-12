# Not great to have divergence between kitchen tests and production systems,
# but we still use the ubuntu user to run kitchen-ec2, even though we don't use
# the ubuntu user anywhere else.
if !ENV['TEST_KITCHEN']
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
