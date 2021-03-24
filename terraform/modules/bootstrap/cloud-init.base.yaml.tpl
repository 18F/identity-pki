# cloud-config

# This file is a terraform template.

# Run apt update / upgrade
repo_update: true
repo_upgrade: all

# Don't attempt to print SSH authorized_keys fingerprints, since we delete the
# ubuntu user. https://github.com/18F/identity-devops-private/issues/1168
no_ssh_fingerprints: true

# make it so that we don't do DSA keys, which do not work with FIPS
ssh_genkeytypes: ['rsa', 'ecdsa']


write_files:
 - path: /etc/login.gov/info/env
   content: "${env}\n"

 - path: /etc/login.gov/info/sns_topic_arn
   content: "${sns_topic_arn}\n"  

 - path: /etc/login.gov/info/domain
   content: "${domain}\n"

 - path: /etc/login.gov/info/role
   content: "${role}\n"

 - path: /etc/login.gov/info/auto-scaled
   content: "true\n"

 - path: /etc/login.gov/info/chef-attributes.json
   content: |
     {
       "run_list": ["role[${role}]"],
       "provisioner": {
         "name": "cloud-init",
         "auto-scaled": true,
         "role": "${role}"
       }
     }

 - path: /etc/login.gov/info/proxy_server
   content: "${proxy_server}"
 - path: /etc/login.gov/info/proxy_port
   content: "${proxy_port}"
 - path: /etc/login.gov/info/no_proxy_hosts
   content: "${no_proxy_hosts}"

 - path: /etc/login.gov/info/http_proxy
   content: "${proxy_url}"

${apt_proxy_stanza}
 - path: /etc/ssh/ssh_known_hosts
   content: |
     # https://help.github.com/articles/github-s-ssh-key-fingerprints/
     github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==

# merge multipart cloud-init files in a sane way
merge_type: 'list(append)+dict(recurse_array)+str()'
