# # encoding: utf-8

# Inspec test for recipe canonical_hostname::aws_metadata_test

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe file('/etc/canonical_hostname') do
  it { should exist }
  its('content') { should match 'canonical-hostname-test-i-[0-9a-z]*.integration.login.gov.internal' }
end
