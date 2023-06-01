#  cis 4.2.3 Ensure permissions on all logfiles are configured
execute "Ensure permissions on all logfiles are configured" do
  command "find /var/log -type f -exec chmod g-wx,o-rwx {} + -o -type d -exec chmod g-w,o-rwx {} +"
  user 'root'
  group 'root'
end

# 6.2.7 Ensure users' dot files are not group or world writable (Automated)
bash "Ensure users' dot files are not group or world writable" do
  code <<-EOH
    #!/bin/bash
    awk -F: '($1!~/(halt|sync|shutdown)/ && $7!~/^(\/usr)?\/sbin\/nologin(\/)?$/ && $7!~/(\/usr)?\/bin\/false(\/)?$/) { print $1 " " $6 }' | while read -r user dir; do
      if [ -d "$dir" ]; then
        for file in "$dir"/.*; do
          if [ ! -h "$file" ] && [ -f "$file" ]; then
            fileperm=$(stat -L -c "%A" "$file")
            if [ "$(echo "$fileperm" | cut -c6)" != "-" ] || [ "$(echo"$fileperm" | cut -c9)" != "-" ]; then
              chmod go-w "$file"
            fi
          fi
        done
      fi
    done
  EOH
end

directory 'Fix /var/log permissions' do
  mode '1775'
  user 'root'
  group 'syslog'
  path '/var/log'
end
