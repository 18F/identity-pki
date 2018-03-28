ruby_block "grub" do
    block do
      file = Chef::Util::FileEdit.new("/etc/default/grub")
      file.search_file_replace('GRUB_CMDLINE_LINUX="audit=1"', 'GRUB_CMDLINE_LINUX="ipv6.disable=1 audit=1"')
      file.write_file
    end
end

bash 'updategrub' do
    code 'update-grub'
end