# # encoding: utf-8

# Inspec test for recipe aws_s3::download and aws_s3::upload

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe file('/etc/round_tripped_s3_content') do
  it { should exist }
  its('content') { should match 'TEST CONTENT' }
end
