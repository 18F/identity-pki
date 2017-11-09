# Common packages and config used by all hosts

package [
  'bmon',
  'bwm-ng',
  'colordiff',
  'dstat',
  'htop',
  'iftop',
  'iotop',
  'iperf',
  'moreutils',
  'ncdu',
  'nethogs',
  'pigz',
  'pv',
  'pydf',
  'tree',
]

# common scripts and aliases

cookbook_file '/usr/local/bin/id-apt-upgrade' do
  source 'id-apt-upgrade'
  owner 'root'
  group 'root'
  mode '0755'
end

cookbook_file '/usr/local/bin/id-chef-client' do
  source 'id-chef-client'
  owner 'root'
  group 'root'
  mode '0755'
end

cookbook_file '/usr/local/bin/id-git' do
  source 'id-git'
  owner 'root'
  group 'root'
  mode '0755'
end

cookbook_file '/usr/local/bin/git-with-key' do
  source 'git-with-key'
  owner 'root'
  group 'root'
  mode '0755'
end
