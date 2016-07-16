Bootstrap a node:

```
knife bootstrap ubuntu@node.login.gov \
  --node-name you_pick_I_prefer_hostnames \
  --run-list 'role[base]','role[app]' \
  --secret-file .chef/data_bag_secret \
  --sudo
```

Subequent runs:

```
# provision all hosts with app role
knife ssh "role:app" -x ubuntu "sudo chef-client"
```

Synchronize local (repo) cookbooks with server:

```
# upload cookbooks to server if the gh repo is not in sync with the server
# TODO: JJG remove --force once the locks/spork is properly setup.
knife cookbook upload -a --force login_dot_gov passenger
```
