# # encoding: utf-8

# Inspec test for recipe aws_metadata::aws_metadata_test

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe file('/etc/aws_metadata/aws_account_id') do
  it { should exist }
  its('content') { should match '^[0-9]*$' }
end

describe file('/etc/aws_metadata/aws_instance_id') do
  it { should exist }
  its('content') { should match 'i-' }
end

describe file('/etc/aws_metadata/aws_region') do
  it { should exist }
  its('content') { should match 'us-' }
end

describe file('/etc/aws_metadata/aws_vpc_id') do
  it { should exist }
  its('content') { should match 'vpc-' }
end
