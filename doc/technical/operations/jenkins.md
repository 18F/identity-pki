# Jenkins

NOTE.  These docs apply to the [chef server
model](../operations/chef-server.md).  These steps are different for nodes that
self bootstrap in auto scaling groups.  See the [Getting Starting
Guide](../../getting-started.md) for the latest documentation.

## Jenkins Users and Admins

Jenkins will need to be set up too!

Admins and users for jenkins can be set up by editing the attributes in the environment:

```
default['identity-jenkins']['users'] = ['username','username2']
default['identity-jenkins']['admins'] = ['admin1','admin2']

```

A chef-client run will make sure that all of those things get applied.

## Chef Jenkins Key

On the `chef` server, locate the `/root/jenkins.pem` key. This is used for
Jenkins to be able to connect to chef. You will need to import this into the
Jenkins web interface.

As a jenkins admin user, from the top level of the jenkins UI, go to "Manage
Jenkins", then click on "Configure System", then set up "Chef Identity
Management". Add the key in for the "jenkins" user from chef.

The Jenkins form has a few fields that you should supply under "Chef Identities":

- **Identity Name:** `jenkins`
- **user.pem key:** Use the value you got from `/root/jenkins.pem` on the `chef` server.
- **knife.rb file:** Use this as the input:
```ruby
current_dir = File.dirname(__FILE__)
log_level                :info
log_location             STDOUT
node_name                "jenkins"
client_key               "#{current_dir}/user.pem"
chef_server_url          "https://chef.login.gov.internal/organizations/login-dev"
cookbook_path            ["#{current_dir}/../kitchen/cookbooks"]
```

**WARNING:** The Chef Identity Management plugin seems to be not very robust.
It has a bug where if you need to modify these values in the web interface,
this will have **no effect**, and your changes will be silently ignored. If you
do need to edit `knife.rb` or the other parameters, be sure to clear out the
values from the Jenkins workspace before running jobs again, with something
like this:

    rm -rf /var/lib/jenkins/workspace/Deploy*/.chef

I (tspencer) would love to make this automatically configured too, but it stores these things as secrets, which means that they are encrypted on a host-by-host basis, so there's no good way to template-ize them that I know of.

## Jenkins/ELK Password Hash

You will also need to set up password hashes in the users databag if they haven't already been set up:

```
$ htpasswd -B -C 12 -c /tmp/htpasswd <username>
New password:
Re-type new password:
Adding password for user username
$

```

Then get the hash out of /tmp/htpasswd and put it in the users databag:

```
knife block use <env>
knife data bag edit users username

```

It should have other attributes in it, but it should look like this:

```
{
  "id": "username",
  "password": "$XXX$YYYZZ$BIGHASHHERE.",

```

This password is what users will use to get into jenkins/ELK. This basic auth stuff can get replaced with SAML or LDAP or something someday.

## Jenkins Usage

* Make sure you are either in the GSA network (VPN or office), or are otherwise in the allowed IP whitelist.
* Go to the jenkins URL you got form terraform.
* Log in using your username/password from the users databag.
* Run the deploy stack job.
  * Input the gitref that you want to use to deploy the code. This can be a tag or a branch.
  * If infrastructure needs to change, that build will fail. Contact a devops person to ensure that gets pushed out before deploy. Someday we hope to make the AWS keys non-readonly so that jenkins can push infrastructure too, but that requires a lot of scrutiny, so we are avoiding that for now.
  * If the infrastructure doesn't need changing, it will push out the code too.
* Enjoy!

You can also use:

```
bin/jenkin.sh
```

From the root of `identity-devops`.
