#
# Cookbook:: cookbook_example
# Spec:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.

require 'spec_helper'
require 'json'

describe 'cookbook_example' do
  context 'When all attributes are default, on an Ubuntu 14.04' do

    let(:chef_environment) { "unittest" }

    let(:environment_configuration) {
      environment_json = File.read(File.join(File.dirname(__FILE__), "../environments/#{chef_environment}.json"))
      environment_json = JSON.parse(environment_json)
      environment_json["default_attributes"]["unittest_mode"] = true
      environment_json
    }

    let(:config_databags) {
      config_databag_json = File.read(File.join(File.dirname(__FILE__), "../data_bags/config/app.json"))
      config_databag_json = JSON.parse(config_databag_json)
      config_databags = {}
      config_databags['app'] = config_databag_json
      config_databags
    }

    let(:user_databags) {
      user_databag_paths = Dir[File.join(File.dirname(__FILE__), '../data_bags/users/*')]
      user_databags = {}
      user_databag_paths.each do |user_databag_path|
        user_databag_json = File.read(user_databag_path)
        user_databag = JSON.parse(user_databag_json)
        user_databags[user_databag['id']] = user_databag
      end
      user_databags
    }

    let(:chef_run) do
      runner = ChefSpec::ServerRunner.new(
        step_into: ['users_manage'],
        platform: 'ubuntu',
        version: '14.04'
      ) do |node, server|
        # https://github.com/sethvargo/chefspec#mocking-out-environments
        server.create_environment(chef_environment, environment_configuration)
        server.create_data_bag('users', user_databags)
        server.create_data_bag('config', config_databags)
        node.chef_environment = chef_environment
      end
      runner.converge(described_recipe)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'creates file with terraform version from environment' do
      expect(chef_run).to render_file('/etc/terraform-version').with_content('0.8.8')
    end

    it 'creates file with slackwebhook from config databag' do
      expect(chef_run).to render_file('/etc/slackwebhook').with_content('https://hooks.slack.com/services/XXX')
    end

    it 'creates file with user comment from user databag' do
      expect(chef_run).to render_file('/etc/usercomment').with_content('Test User')
    end
  end
end
