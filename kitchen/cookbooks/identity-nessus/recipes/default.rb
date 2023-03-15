#
# Cookbook Name:: identity-nessus
# Recipe:: default
#
# Copyright 2017, YOUR_COMPANY_NAME
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

unless ['pt', 'pt2'].include?(node.chef_environment)

  nessus_key = ConfigLoader.load_config(node, "nessus_agent_key", common: true).chomp!
  nessus_host = ConfigLoader.load_config(node, "nessus_host", common: true).chomp!

  execute 'register_with_nessus' do
    command "/opt/nessus_agent/sbin/nessuscli agent link --key=\"#{nessus_key}\" --name=\"#{node['hostname']}\" --groups=\"#{node.chef_environment}\" --host=\"#{nessus_host}\" --port=8834 && touch /root/nessus_is_registered"
    not_if { ::File.exist?('/root/nessus_is_registered') }
    ignore_failure true
    sensitive      true
  end

  systemd_unit 'nessus-cleanup.service' do
    content('Unit' => {
              'Description' => 'Delete my own nessus client registration at shutdown/termination',
              'DefaultDependencies' => 'no',
              'Before' => 'shutdown.target halt.target',
            },
            'Service' => {
              'Type' => 'oneshot',
              'ExecStart' => "/opt/nessus_agent/sbin/nessuscli agent unlink",
            },
            'Install' => {
              'WantedBy' => 'halt.target shutdown.target',
            })
    action [:create, :enable]
  end
end