include_recipe 'login_dot_gov::system_users'

known_hosts = [
  '# dropped off by chef',
  '# https://help.github.com/articles/github-s-ssh-key-fingerprints/',
  'github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==',
]

file '/etc/ssh/ssh_known_hosts' do
  owner 'root'
  group 'root'
  mode '0644'
  content known_hosts.join("\n") + "\n"
end

cookbook_file '/etc/ssh/ssh_config' do
  owner 'root'
  group 'root'
  source 'etc_ssh_config'
end

# group able to use github SSH keys
group 'github' do
  members ['root', node.fetch('login_dot_gov').fetch('system_user')]
end

# This is needed to create this directory on non-ASG servers
directory '/etc/login.gov'

directory '/etc/login.gov/keys' do
  owner 'root'
  group 'root'
  mode '0751'
end

file '/etc/login.gov/keys/id_ecdsa.identity-servers' do
  # SSH complains if key is group readable only when you are the owner
  # so we set the owner to sys since that's a unused user that will never need
  # to actually use the key.
  # Add users to the 'github' group in order to read the key.
  owner 'sys'
  group 'github'
  mode '0640'
  content ConfigLoader.load_config(node, 'id_ecdsa.identity-servers', common: true)
  sensitive true
end

file '/etc/login.gov/keys/id_ecdsa.identity-servers.pub' do
  owner 'root'
  group 'root'
  mode '0644'
  content ConfigLoader.load_config(node, 'id_ecdsa.identity-servers.pub', common: true)
end
