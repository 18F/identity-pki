# # encoding: utf-8

# Inspec test for recipe chef_proxy_env::default

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

# TODO
describe file('/nonexistent') do
  it { should exist }
end
