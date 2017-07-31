#
# Cookbook:: aws_s3
# Recipe:: download
#
# Copyright:: 2017, The Authors, All Rights Reserved.

# NOTE: This is only for test purposes.  Use the library directly as shown here.

instance_id = Chef::Recipe::AwsMetadata.get_aws_instance_id
test_bucket_prefix = node['aws_s3']['test_bucket_prefix']
aws_region = Chef::Recipe::AwsMetadata.get_aws_region
aws_account_id = Chef::Recipe::AwsMetadata.get_aws_account_id
bucket = "#{test_bucket_prefix}-#{aws_region}-#{aws_account_id}"
key = "#{node.chef_environment}/aws-s3-cookbook-integration-test-#{instance_id}"

content = AwsS3.download(bucket, key)

file '/etc/round_tripped_s3_content' do
  content content
end
