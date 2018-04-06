script 'remove rwx' do
    interpreter "bash"
    code <<-EOH
        chmod o=, g-w /opt/opscode/embedded || true
        chmod o=, g-w /usr/share/logstash || true
    EOH
end

