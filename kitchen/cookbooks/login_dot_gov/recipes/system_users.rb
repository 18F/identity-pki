# create service users
['system_user','web_system_user'].each do |user|
  service_user = node.fetch('login_dot_gov').fetch(user)  
  group service_user do
    system true
  end
  user service_user do
    home "/home/#{service_user}"
    manage_home true
    shell '/usr/sbin/nologin'
    system true
    gid service_user
  end
  directory "/home/#{service_user}" do
    mode '755'
    owner service_user
    group service_user
  end
end

# explicitly set up ssm-user up front instead of relying on ssm magic
user 'ssm-user' do
  shell  '/bin/sh'
  gid    'users'
  home   '/home/ssm-user'
end

sudo 'ssm-user' do
  users 'ssm-user'
  nopasswd true
end

# change permissions on ssm homedir to satisfy CIS benchmark
directory "/home/ssm-user" do
  mode '750'
  owner 'ssm-user'
  group 'users'
end
