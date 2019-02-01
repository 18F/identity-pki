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
      proxy_server: 'http://obproxy.login.gov.internal',
      proxy_port: '3128',
    })
    notifies :restart, 'service[clamav-freshclam]', :delayed
    notifies :restart, 'service[clamav-daemon]', :delayed
end

service 'clamav-freshclam' do
    action [:enable, :start]
    supports :restart => true, :status => true, :start => true, :stop => true
end

service 'clamav-daemon' do
    action [:enable, :start]
    supports :restart => true, :status => true, :start => true, :stop => true
end