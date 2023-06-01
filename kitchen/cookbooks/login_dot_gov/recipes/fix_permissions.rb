# Correct permissions after setup and checkout, otherwise the websrv user can't access bundle
execute 'Update permissions on /srv' do
  command 'find /srv ! -type l -exec chmod o+X {} +'
  only_if '[ -d /srv ]'
end

execute "Make sure /srv is owned by #{node['login_dot_gov']['system_user']}" do
  command "find /srv ! -type l -exec chown #{node['login_dot_gov']['system_user']}:#{node['login_dot_gov']['system_user']} {} +"
  only_if '[ -d /srv ]'
end

execute "Make sure /opt/ruby_build is owned by #{node['login_dot_gov']['system_user']}" do
  command "find /opt/ruby_build/ -exec chown #{node['login_dot_gov']['system_user']}:#{node['login_dot_gov']['system_user']} {} +"
  only_if '[ -d /opt/ruby_build ]'
end

# Puts websrv in the appinstall group so it can actually access the application files needed to run
group "Add websrv to #{node['login_dot_gov']['system_user']}" do
  group_name node['login_dot_gov']['system_user']
  members [node['login_dot_gov']['system_user'], 'websrv']
end

# Update nginx files to also be owned by appinstall so websrv can access it as well otherwise nginx breaks
execute 'Update permissions on /srv' do
  command "find /opt/nginx ! -type l -exec chown #{node['login_dot_gov']['system_user']}:#{node['login_dot_gov']['system_user']} {} +"
  only_if '[ -d /opt/nginx ]'
end

# Passenger runs as websrv
execute 'Fix log directory permissions' do
  command "chown -R #{node['login_dot_gov']['system_user']}:#{node['login_dot_gov']['system_user']} /srv/idp/shared/log"
  only_if '[ -d /srv/idp/shared/log ]'
end
