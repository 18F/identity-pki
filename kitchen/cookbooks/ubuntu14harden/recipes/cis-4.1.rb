template '/etc/audit/audit.rules' do
    source 'audit.rules.erb'
    owner 'root'
    group 'root'
    mode '0640'
end