identity_devops_local_path = '/etc/login.gov/repos/identity-devops'

execute 'tag instance from identity-devops sha' do
  command "aws ec2 create-tags --region #{node['ec2']['region']} --resources #{node['ec2']['instance_id']} --tags Key=gitsha:identity-devops,Value=$(cd #{identity_devops_local_path} && git rev-parse HEAD)"
  ignore_failure true
end
