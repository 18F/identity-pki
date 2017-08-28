#
# Cookbook:: canonical_hostname
# Recipe:: canonical_hostname_test
#
# Copyright:: 2017, The Authors, All Rights Reserved.

# This is only for test purposes.  Do not include this recipe.
file '/etc/canonical_hostname' do
  content CanonicalHostname.get_hostname
end
