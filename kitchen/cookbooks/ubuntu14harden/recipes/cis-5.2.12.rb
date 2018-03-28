ruby_block "sshd_config" do
    block do
        file = Chef::Util::FileEdit.new("/etc/ssh/sshd_config")
        file.search_file_replace('ClientAliveInterval 300', 'ClientAliveInterval 900')
        file.write_file
    end
end
