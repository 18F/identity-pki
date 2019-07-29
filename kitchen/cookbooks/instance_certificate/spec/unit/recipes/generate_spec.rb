#
# Cookbook Name:: instance_certificate
# Spec:: generate
#
# Copyright (c) 2017 The Authors, All Rights Reserved.

require 'spec_helper'

describe 'instance_certificate::generate' do
  context 'When overriding the subject' do
    let(:chef_run) do
      runner = ChefSpec::ServerRunner.new(
        step_into: ['generate'],
        platform: 'ubuntu',
        version: '14.04'
      ) do |node, server|
        node.chef_environment = "unittest"
        environment = { "name": node.chef_environment, "default_attributes": { "instance_certificate": { "subject": "CN=example.com.internal" } } }
        server.create_environment(node.chef_environment, environment)
      end
      runner.converge(described_recipe)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'creates server certificate file' do
      expect(chef_run).to render_file('/etc/ssl/certs/server.crt').with_content('BEGIN CERTIFICATE')
    end

    it 'creates server key file' do
      expect(chef_run).to render_file('/etc/ssl/private/server.key').with_content('BEGIN RSA PRIVATE KEY')
    end
  end

  context 'When overriding the key paths' do
    let(:chef_run) do
      runner = ChefSpec::ServerRunner.new(
        step_into: ['generate'],
        platform: 'ubuntu',
        version: '14.04'
      ) do |node, server|
        node.chef_environment = "unittest"
        attributes = { "instance_certificate": { "key_path": "/var/nonexistent/dir/whoah.key",
                                                 "cert_path": "/var/other/nonexistent/dir/whee.crt",
                                                 "subject": "CN=example.com.internal" } }
        environment = { "name": node.chef_environment, "default_attributes": attributes }
        server.create_environment(node.chef_environment, environment)
      end
      runner.converge(described_recipe)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'creates server certificate directory' do
      expect(chef_run).to create_directory("/var/other/nonexistent/dir")
    end

    it 'creates server key directory' do
      expect(chef_run).to create_directory("/var/nonexistent/dir")
    end

    it 'creates server certificate file' do
      expect(chef_run).to render_file("/var/other/nonexistent/dir/whee.crt").with_content('BEGIN CERTIFICATE')
    end

    it 'creates server key file' do
      expect(chef_run).to render_file("/var/nonexistent/dir/whoah.key").with_content('BEGIN RSA PRIVATE KEY')
    end
  end

  context 'when using default subject' do
    let(:chef_run) do
      runner = ChefSpec::ServerRunner.new(
        step_into: ['generate'],
        platform: 'ubuntu',
        version: '14.04'
      ) do |node, server|
        node.chef_environment = "unittest"
        attributes = { "instance_certificate": {} }
        environment = { "name": node.chef_environment, "default_attributes": attributes }
        server.create_environment(node.chef_environment, environment)
      end
      runner.converge(described_recipe)
    end

    before do
      expect(::Chef::Recipe::CanonicalHostname).to receive(:get_hostname).and_return('rspec-host.example.com')
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'creates server certificate file' do
      expect(chef_run).to render_file('/etc/ssl/certs/server.crt').with_content('BEGIN CERTIFICATE')
    end

    it 'creates server key file' do
      expect(chef_run).to render_file('/etc/ssl/private/server.key').with_content('BEGIN RSA PRIVATE KEY')
    end
  end
end
