# cloud-config

# This file is a terraform template, so be careful with unescaped $ and {}!

# Run apt update / upgrade
repo_update: true
repo_upgrade: all

write_files:
 - path: /etc/login.gov/info/env
   content: "${env}\n"

 - path: /etc/login.gov/info/domain
   content: "${domain}\n"

 - path: /etc/login.gov/info/role
   content: "${role}\n"

 - path: /etc/ssh/ssh_known_hosts
   content: |
     # https://help.github.com/articles/github-s-ssh-key-fingerprints/
     github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==


runcmd:
 - /var/lib/cloud/instance/scripts/provision.sh --kitchen-subdir kitchen --chef-download-url "${chef_download_url}" --chef-download-sha256 "${chef_download_sha256}" --git-ref "${main_git_ref}" "${main_s3_ssh_key_url}" "${main_git_clone_url}" || echo 'MAIN CHEF RUN FAILED'
 - /var/lib/cloud/instance/scripts/provision.sh --chef-download-url "${chef_download_url}" --chef-download-sha256 "${chef_download_sha256}" --git-ref "${private_git_ref}" "${private_s3_ssh_key_url}" "${private_git_clone_url}"
 - touch /run/cloudinit-finished


# merge multipart cloud-init files in a sane way
merge_type: 'list(append)+dict(recurse_array)+str()'
