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

nessus_key = ConfigLoader.load_config(node, "nessus_agent_key", common: true).chomp!
nessus_host = ConfigLoader.load_config(node, "nessus_host", common: true).chomp!

package 'postfix'
package 'openssh-server'
package 'ca-certificates'
package 'tzdata'
package 'perl'

execute 'grab_gitlab_repo' do
  command 'curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash'
  ignore_failure true
end

ENV['EXTERNAL_URL'] = "https://gitlab.#{node.chef_environment}.gitlab.identitysandbox.gov"
package 'gitlab-ee'
