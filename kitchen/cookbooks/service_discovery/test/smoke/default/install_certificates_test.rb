# # encoding: utf-8

# Inspec test for recipe service_discovery::discover

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe directory('/etc/trusted_nodes') do
 it { should exist }
end

control 'check-certs-installed' do
  ls_out_nosuffix = command('ls /etc/trusted_nodes/*internal.crt')
  describe ls_out_nosuffix do
    its('exit_status') { should eq 0 }
    its('stdout') { should match '^/etc/trusted_nodes/service-discovery-test-i-[0-9a-z]*.ci.login.gov.internal.crt$' }
  end

  cat_out_nosuffix = command("cat #{ls_out_nosuffix.stdout.chomp}")
  describe cat_out_nosuffix do
    its('exit_status') { should eq 0 }
    its('stdout') { should match 'BEGIN CERTIFICATE' }
  end

  ls_out_suffix = command('ls /etc/trusted_nodes/*legacy.crt')
  describe ls_out_suffix do
    its('exit_status') { should eq 0 }
    its('stdout') { should match '^/etc/trusted_nodes/service-discovery-test-i-[0-9a-z]*.ci.login.gov.internal-legacy.crt$' }
  end

  cat_out_suffix = command("cat #{ls_out_suffix.stdout.chomp}")
  describe cat_out_suffix do
    its('exit_status') { should eq 0 }
    its('stdout') { should match 'BEGIN CERTIFICATE' }
  end
end
