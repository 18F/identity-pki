#
# Cookbook Name:: apt_update
# Spec:: default

require 'spec_helper'

describe 'apt_update::upgrade' do
  context 'When all attributes are default, on ubuntu platform' do
      let(:chef_run) do
         ChefSpec::ServerRunner.new(platform: 'ubuntu', version: '14.04')
                          .converge(described_recipe)
      end
  
     it 'converges successfully' do
      expect { chef_run }.to_not raise_error
     end
     it 'upgrades apt repo' do
      expect(chef_run).to run_execute('apt-get upgrade -y --force-yes')
      expect(chef_run).to run_execute('apt-get dist-upgrade -y --force-yes')
     end
  end
end
