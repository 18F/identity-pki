# cloud-config

# This file is a terraform template.

# Don't attempt to print SSH authorized_keys fingerprints, since we delete the
# ubuntu user. https://github.com/18F/identity-devops-private/issues/1168
no_ssh_fingerprints: true

# make it so that we don't do DSA keys, which do not work with FIPS
ssh_genkeytypes: ['rsa', 'ecdsa']

bootcmd:
 - aws configure set region ${region} --profile default
 - mkdir -vp /etc/auto-hostname
 - 'echo "${hostname_prefix}" > /etc/auto-hostname/prefix'
 - 'echo "${env}.${domain}" > /etc/auto-hostname/domain'

preserve_hostname: true

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

 - path: /etc/default/motd-news
   content: "ENABLED=0"

${apt_proxy_stanza}
 - path: /etc/ssh/ssh_known_hosts
   content: |
     # https://help.github.com/articles/github-s-ssh-key-fingerprints/
     github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=

runcmd:
- /var/lib/cloud/instance/scripts/provision.sh --asg-name "${asg_name}" --lifecycle-hook-name "${private_lifecycle_hook_name}" --git-ref "${private_git_ref}" "${private_s3_ssh_key_url}" "${private_git_clone_url}"
- touch "/run/private-provisioning"
- /var/lib/cloud/instance/scripts/provision.sh --kitchen-subdir kitchen --berksfile-toplevel --asg-name "${asg_name}" --lifecycle-hook-name "${main_lifecycle_hook_name}" --git-ref "${main_git_ref}" "${main_s3_ssh_key_url}" "${main_git_clone_url}"
- touch "/run/main-provisioning"
- "apt remove -y ubuntu-advantage-pro ubuntu-advantage-tools"
- "aideinit --force --yes && touch /var/tmp/ran-aideinit"