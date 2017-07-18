# # encoding: utf-8

# Inspec test for recipe cookbook_example::default

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe file('/etc/terraform-version') do
  its('content') { should match '0\.8\.8' }
end

describe file('/etc/usercomment') do
  its('content') { should match 'Test User' }
end

describe file('/etc/slackwebhook') do
  its('content') { should match 'https://hooks.slack.com/services/XXX' }
end
