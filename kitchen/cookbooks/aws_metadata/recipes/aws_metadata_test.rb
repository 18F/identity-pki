#
# Cookbook:: aws_metadata
# Recipe:: aws_metadata_test
#
# Copyright:: 2017, The Authors, All Rights Reserved.

directory '/etc/aws_metadata'

file '/etc/aws_metadata/aws_account_id' do
  content AwsMetadata.get_aws_account_id
end

file '/etc/aws_metadata/aws_instance_id' do
  content AwsMetadata.get_aws_instance_id
end

file '/etc/aws_metadata/aws_region' do
  content AwsMetadata.get_aws_region
end

file '/etc/aws_metadata/aws_vpc_id' do
  content AwsMetadata.get_aws_vpc_id
end

file '/etc/aws_metadata/aws_vpc_cidr' do
  content AwsMetadata.get_aws_vpc_cidr
end

