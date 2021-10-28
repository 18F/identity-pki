# remove connection limiting config in pt
if node.chef_environment == 'pt'
  execute "ruby -i -ne 'print if not /limit_conn.*/' /opt/nginx/conf/nginx.conf"
  execute "systemctl restart passenger"
end
