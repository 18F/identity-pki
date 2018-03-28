ruby_block "login.defs" do
    block do
        file = Chef::Util::FileEdit.new("/etc/login.defs")
        file.search_file_replace('PASS_MIN_DAYS   7', 'PASS_MIN_DAYS   0')
        file.write_file
    end
end
