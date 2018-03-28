script 'remove rwx' do
    interpreter "bash"
    code <<-EOH
        chmod o=, g-x /opt/opscode/embedded || true
        chmod o=, g-x /usr/share/logstash || true
    EOH
end

