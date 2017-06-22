#
# Cookbook Name:: apt_update
# Spec:: default

require 'spec_helper'

describe 'apt_update::update' do
  context 'When all attributes are default, on ubuntu platform' do
      let(:chef_run) do
         ChefSpec::ServerRunner.new(platform: 'ubuntu', version: '14.04')
                          .converge(described_recipe)
      end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end
    it 'updates apt repo' do
      expect(chef_run).to update_apt_update("update ubuntu machine in _default")
    end
  end
end
