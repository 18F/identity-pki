# # encoding: utf-8

# Inspec test for recipe config_loader::default

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe file('/etc/slackwebhook') do
  its('content') { should match 'https://hooks.slack.com/services/XXX' }
end
