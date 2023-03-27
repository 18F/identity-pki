include_recipe 'login_dot_gov::system_users'

known_hosts = [
  '# dropped off by chef',
  '# https://help.github.com/articles/github-s-ssh-key-fingerprints/',
  'github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=',
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
