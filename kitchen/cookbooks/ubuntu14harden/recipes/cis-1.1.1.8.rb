
ruby_block "insert_vfat" do
    block do
        file = Chef::Util::FileEdit.new("/etc/modprobe.d/CIS.conf")
        file.insert_line_if_no_match("install vfat /bin/true", "install vfat /bin/true")
        file.write_file
    end
end
