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
