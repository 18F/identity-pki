case Chef::Recipe::AwsMetadata.get_aws_account_id
when /\A55554/
  default['login_dot_gov']['domain_name'] = 'login.gov'
when /\A89494/
  default['login_dot_gov']['domain_name'] = 'identitysandbox.gov'
else
  raise "Unexpected AWS account ID: #{Chef::Recipe::AwsMetadata.get_aws_account_id.inspect}"
end