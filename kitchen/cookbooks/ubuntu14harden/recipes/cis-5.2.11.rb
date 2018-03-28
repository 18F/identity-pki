ruby_block "insert_MACs" do
    block do
        file = Chef::Util::FileEdit.new("/etc/ssh/sshd_config")
        file.insert_line_if_no_match("MACs", "MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com")
        file.write_file
    end
end
