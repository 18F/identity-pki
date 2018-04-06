script 'remove unowned files' do
    interpreter "bash"
    code <<-EOH
        rm -rf /var/chef/backup/home/dnesting || true
        rm -rf /var/chef/backup/home/zmargolis || true
        rm -rf /home/sverch || true
        rm -rf /home/zmargolis || true
        rm -rf /home/astone || true
        rm -rf /home/dnesting || true
        rm -rf /home/tspencer || true
    EOH
end

bash 'remove COPYING file' do
    code 'sudo find /opt/aws/ -type f -name COPYING -exec rm -r {} + || true'
end