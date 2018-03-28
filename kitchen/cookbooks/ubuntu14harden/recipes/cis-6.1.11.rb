script 'remove unowned files' do
    interpreter "bash"
    code <<-EOH
        rm -rf /opt/aws/awsagent/kmods/1.0.47.0/COPYING || true
        rm -rf /var/chef/backup/home/dnesting || true
        rm -rf /var/chef/backup/home/zmargolis || true
        rm -rf /home/sverch || true
        rm -rf /home/zmargolis || true
        rm -rf /home/astone || true
        rm -rf /home/dnesting || true
        rm -rf /home/tspencer || true
    EOH
end