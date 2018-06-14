# # encoding: utf-8

# Inspec tests for proxy node

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe user('proxy') do
    it { should exist }
  end
  
  describe service('ssh') do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end
  
  describe service('squid') do
    it { should be_installed }
    it { should be_enabled }
  end
  
  describe port(3128) do
    it { should be_listening }
    its('processes') {should include 'squid'}
  end
  
  # make sure we can sudo
  describe command('sudo whoami') do
    its('stdout') { should eq "root\n" }
    its('exit_status') { should eq 0 }
  end
  