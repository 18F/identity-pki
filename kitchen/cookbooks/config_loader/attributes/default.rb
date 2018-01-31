default['citadel']['region'] = Chef::Recipe::AwsMetadata.get_aws_region
default['citadel']['bucket'] = "login-gov.secrets.#{Chef::Recipe::AwsMetadata.get_aws_account_id}-#{Chef::Recipe::AwsMetadata.get_aws_region}"
