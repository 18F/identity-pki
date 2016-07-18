## Terraform

### Initial Setup

Make sure you have set the required env vars using the env.sh helper file or by
other means (/etc/env, etc.)

Install aws cli tools and ChefDK

```
brew install awscli Caskroom/cask/chefdk
```

Configure (set the region to us-east-1 if you're using the 18f-sandbox account)

```
aws configure
```

### Basic Execution

Check the `terraform-app` plan against the current state of that environment. 

```
./deploy plan terraform-app
```

The environment defaults to `tf` which is a highly volatile env meant for testing out new terraform
configs. We can remove that env and change the default to `dev` once the churn slows down.

Apply any changes to the `tf` env using the terraform-app plan

```
./deploy apply terraform-app
```

Destroy all resources in an env

```
./deploy destroy terraform-app
```

Modify the `TF_VAR_env_name` to work with the other environments (`dev`, `qa`, `pt`, `staging`, `dm`, `production`)

## Chef

Install or update the chef server and related infrastructure

```
./deploy plan terraform-chef
```

```
./deploy apply terraform-chef
```

Bootstrap (install chef-client on a host and add the node to the chef server)

```
knife bootstrap ubuntu@tf.login.gov \
  --json-attributes '{ "set_fqdn": "tf.login.gov" }' \
  --node-name tf \
  --run-list 'role[base]','role[app]' \
  --secret-file .chef/data_bag_secret \
  --sudo
```

Wait ~12m.

Subequent runs:

```
# provision all hosts with app role
knife ssh "role:app" -x ubuntu "sudo chef-client"

# provision host with name dev
knife ssh "name:dev" -x ubuntu "sudo chef-client"

# provision based on fqdn
knife ssh "fqdn:*tf.login.gov" -x ubuntu "sudo chef-client"
```

Synchronize local (repo) cookbooks with server:

```
# upload cookbooks to server if the gh repo is not in sync with the server
knife cookbook upload -a login_dot_gov passenger
```

## Notes

Generate a long string to use as a data bag passprhase (note this is just used as a passprhase to
encrypt the data)

```
openssl rand -hex 2048 > .chef/data_bag.key
```
