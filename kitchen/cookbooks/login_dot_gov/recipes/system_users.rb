# create app service user
group node.fetch('login_dot_gov').fetch('system_user') do
  system true
end
user node.fetch('login_dot_gov').fetch('system_user') do
  home '/home/' + node.fetch('login_dot_gov').fetch('system_user')
  manage_home true
  shell '/usr/sbin/nologin'
  system true
  gid node.fetch('login_dot_gov').fetch('system_user')
end

# create web service user
group node.fetch('login_dot_gov').fetch('web_system_user') do
  system true
end
user node.fetch('login_dot_gov').fetch('web_system_user') do
  home '/nonexistent'
  shell '/usr/sbin/nologin'
  system true
  gid node.fetch('login_dot_gov').fetch('web_system_user')
end
