file '/etc/clamav/freshclam.conf' do
    action :touch
    mode 0644
end

template '/etc/clamav/freshclam.conf' do
    source 'freshclam.conf.erb'
    owner 'root'
    group 'root'
    mode 0444
    variables ({
      :proxyServer => node['login_dot_gov']['proxy_server'],
      :proxyPort => node['login_dot_gov']['proxy_port']
   })
    notifies :restart, 'service[clamav-freshclam]', :delayed
 end

 service 'clamav-freshclam' do
    action [:enable, :start]
    supports :restart => true, :status => true, :start => true, :stop => true
 end