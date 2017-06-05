# Login.gov Infrastructure Repository Getting Started

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [1. Introduction](#1-introduction)
- [2. Dependencies](#2-dependencies)
  - [2.1. Mac OSX](#21-mac-osx)
- [3. Environment Variables File](#3-environment-variables-file)
- [4. Add Bootstrap Key to SSH-Agent](#4-add-bootstrap-key-to-ssh-agent)
- [5. Create a new environment](#5-create-a-new-environment)
  - [5.1. Troubleshooting](#51-troubleshooting)
  - [5.2. Provisioner-created Files](#52-provisioner-created-files)
- [6. Work with an existing environment](#6-work-with-an-existing-environment)
  - [6.1. Terraform](#61-terraform)
  - [6.2. Chef](#62-chef)
    - [6.2.1. Adding a Chef User](#621-adding-a-chef-user)
    - [6.2.2. Knife Setup](#622-knife-setup)
    - [6.2.3. Data Bags](#623-data-bags)
    - [6.2.4. Run Chef Client](#624-run-chef-client)
    - [6.2.5. Berkshelf](#625-berkshelf)
    - [6.2.6. Cookbook Changes](#626-cookbook-changes)
- [7. Create FISMA AMI](#7-create-fisma-ami)
- [8. Create a login.gov base AMI](#8-create-a-logingov-base-ami)
- [9. Manual Lockdown](#9-manual-lockdown)
- [10. Jumphost SSH-Agent and Proxy Forwarding](#10-jumphost-ssh-agent-and-proxy-forwarding)
  - [10.1. Helper Scripts for Common Workflows](#101-helper-scripts-for-common-workflows)
    - [10.1.1 `./bin/ssh.sh`](#1011-binsshsh)
    - [10.1.2 `./bin/elk.sh`](#1012-binelksh)
    - [10.1.2 `./bin/jenkins.sh`](#1012-binjenkinssh)
    - [10.1.3 `./bin/rails-console.sh`](#1013-binrails-consolesh)
  - [10.2. Manual SSH Jumping](#102-manual-ssh-jumping)
- [11. Other Miscellaneous Configurations](#11-other-miscellaneous-configurations)
  - [11.1 Elastic Search](#111-elastic-search)
  - [11.2 CloudTrail](#112-cloudtrail)
  - [11.3 Jenkins](#113-jenkins)
    - [11.3.1 Jenkins Users and Admins](#1131-jenkins-users-and-admins)
    - [11.3.2 Chef Jenkins Key](#1132-chef-jenkins-key)
    - [11.3.3 Jenkins/ELK Password Hash](#1133-jenkinselk-password-hash)
    - [11.3.4 Jenkins Usage](#1134-jenkins-usage)
  - [11.5. Deploying the application](#115-deploying-the-application)
    - [11.5.1. App Control/Config with Rake Tasks](#1151-app-controlconfig-with-rake-tasks)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## 1. Introduction

The [`identity-devops`](https://github.com/18F/identity-private) repository
contains infrastructure configurations for the
[identity-*](https://github.com/18F/identity-private) projects.  This includes
the [Terraform](https://www.terraform.io/docs/commands/) configuration for
provisioning a new [AWS VPC](https://aws.amazon.com/vpc/) and other AWS
elements as well as the [Chef](https://docs.chef.io/chef_overview.html)
cookbooks for configuring instances after they are provisioned.

This document is an introduction for how to work with this repository,
including spinning up a new environment and working with an existing
environment.

## 2. Dependencies

### 2.1. Mac OSX

Install [Homebrew](https://brew.sh) (Ignore this step if you have already run the  [laptop script](https://github.com/18F/laptop)).

```shell
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

Install  [AWS CLI](https://aws.amazon.com/cli/)  in order to manage services from the command line.

``` shell
brew install awscli
```

[Configure the AWS
CLI](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)
with the AWS region (currently us-west-2) and credentials you want to use.  The
18f-identity specific signin link is here:
https://18f-identity.signin.aws.amazon.com/console.  Test your configuration by
running `aws s3 ls`.

Install [ChefDK](https://downloads.chef.io/chefdk).

```shell
brew install Caskroom/cask/chefdk
```

Install [Terraform CLI](https://www.terraform.io/docs/commands/).

- Download Terraform 0.8.8 from https://releases.hashicorp.com/terraform/.
    - We are in the process of upgrading from 0.8.8, check back
      [here](https://github.com/18F/identity-private/issues/1877) for the status of that upgrade.
- Extract it somewhere, like `/usr/local/bin` or `~/bin` and make sure it's in your PATH.

Install [Terraform ACME Provider](https://www.terraform.io/docs/commands/).

``` shell
mkdir $HOME/.terraform-plugins
home=$HOME cat <<EOT > $HOME/.terraformrc
providers {
  acme = "$home/.terraform.plugins/terraform-provider-acme"
}
EOT
curl -LO
ttps://github.com/paybyphone/terraform-provider-acme/releases/download/v0.2.1/terraform-provider-acme_v0.2.1_darwin_amd64.zip
unzip -o terraform-provider-acme_v0.2.1_darwin_amd64.zip -d
HOME/.terraform-plugins
rm terraform-provider-acme_v0.2.1_darwin_amd64.zip
```

## 3. Environment Variables File

We currently use a lot of environment variables for configuration.  Copy
`env/env.sh.example` to `env/env.sh`.  Do not source this directly, it is used
by the `deploy` and `bootstrap.sh` scripts described below.

One thing you may have to change is TF_VAR_app_sg_ssh_cidr_blocks if you're not
on the internal GSA network.  See
https://github.com/18F/identity-private/issues/1769#issuecomment-290822192.
You will have to add your CIDR as the first CIDR in the array until
https://github.com/18F/identity-devops/pull/245 is resolved.

## 4. Add Bootstrap Key to SSH-Agent

We currently use a shared SSH key as part of our bootstrap process, see the
discussion in https://github.com/18F/identity-private/issues/1730.  For now you
need to get that key from someone else on the team, or create your own keypair
in AWS.

You need to add the value of `TF_VAR_key_name` to your ssh-agent, otherwise ssh
handshake will fail. For `identity-devops`, it is `login-dev-us-west-2.pem`.

```shell
ssh-add ~/.ssh/login-dev-us-west-2.pem
```

This will allow you to log in as the `ubuntu` user for any instances that are
provisioned using this keypair.

## 5. Create a new environment

If you're trying to spin up a new environment, run:

```
./bootstrap.sh
```

From the root of the `identity-devops` repo.  That should prompt you for
anything that the setup needs and help you through the process.  If you get
stuck, refer back to the rest of this README for more details.

The main terraform configuration directory is `terraform-app`.

After you've created a new environment, refer to the manual lockdown steps
below.

### 5.1. Troubleshooting

If your initial setup fails, file an issue in `identity-private` to get the
issue fixed in the bootstrap script.

Depending on where the failure happened, your jumphost may not yet have a DNS
name, so you will have to ssh in using the public IP address which can find in
the AWS console.  If you want to get the IP from the command line see
https://github.com/18F/identity-devops/blob/master/bin/chef-configuration-first-run.sh#L17
for an example.

If the issue was in the terraform provisioning step, you can attempt to fix the
issue and continue the deployment using the `deploy` script described below.

### 5.2. Provisioner-created Files

The [Chef
Provisioner](https://github.com/18F/identity-devops/blob/master/terraform-app/chef.tf#L69)
creates several files in your `~/.chef` directory.  After
https://github.com/18F/identity-private/issues/863 is done, this might not
happen any more, but for now, these are some files that may be created:

* `yourusername-<env>.pem`
* `<env>-login-dev-validator.pem`
* `knife-<env>.rb`
* `<env>-databag.key`

## 6. Work with an existing environment

### 6.1. Terraform

To run terraform on an existing environment, use the `deploy` script in the
`identity-devops` repository.  This loads the necessary environment
configuration and runs terraform with whatever options you pass in.

It is recommended that your run `plan` before you run `apply`.  For example:

```
# Should show what terraform would do if you ran apply
./deploy testenv myuser terraform-app plan
# Should apply the plan that the plan command showed
./deploy testenv myuser terraform-app apply
```

The terraform configuration directory for most things in our infrastructure is
`terraform-app`.

### 6.2. Chef

We use Chef to manage machine configuration and user accounts.

#### 6.2.1. Adding a Chef User

If you set up the environment, you should already have a chef user.  If someone
else set up the environment you are trying to work with, you may need to get
the [config databag key](https://github.com/18F/identity-private/issues/1825)
from them, and create a new chef user for yourself.

[This
script](https://github.com/18F/identity-devops/blob/master/bin/createchefclient.sh)
is one way to create a chef user, but you can also use
[knife](https://docs.chef.io/knife_user.html).

#### 6.2.2. Knife Setup

After your environment is already setup, you can run `bin/setup-knife.sh` and
point it at the jumphost.  If someone else set up the environment you are
trying to work with, you may need to get the [config databag
key](https://github.com/18F/identity-private/issues/1825) from them, and create
a new chef user for yourself.

If knife is set up correctly, `knife node list` on the jumphost should list the
nodes in your env/VPC.

#### 6.2.3. Data Bags

We have data bags for our configuration and our user accounts.  See:
https://github.com/18F/identity-private/wiki/Operations:-Chef-Databags.

During the bootstrap process, these should be added automatically by
https://github.com/18F/identity-devops/blob/master/bin/chef-configuration-first-run.sh.

After you have an environment set up and knife configured correctly, you should
be able to modify the user and config data bags using the `knife data bag`
commands.

For example, to edit the config databag:

```shell
knife data bag edit config app # knife[:secret-file] should be set in your knife.rb
```

#### 6.2.4. Run Chef Client

To run the `chef-client` you may not need a chef account as long as you have an
account on the box that can sudo.  Just run `sudo chef-client`.

If you want to use `knife ssh` you can use that to run on multiple nodes that
match a pattern without having to manually ssh in.  For example, `knife ssh
'name:*' 'sudo chef-client'` will run chef-client on all nodes.

#### 6.2.5. Berkshelf

We use [Berkshelf](https://berkshelf.com/v2.0/) to manage our cookbooks, so you
may also need to clone `identity-devops` on the jumphost and install Berkshelf.
See
https://github.com/18F/identity-devops/blob/c7927570c7bcd4ceae4cda0d8f1acf2ce84fb43e/terraform-app/install-chef-server.sh.tpl
for how terraform sets this up on the chef server.

#### 6.2.6. Cookbook Changes

Probably most of the time, you'll just be pushing one cookbook up, so you can
bump the cookbook version number and then do this:

```shell
berks
berks upload identity-jenkins
berks apply <env>
```

If you get a "cookbook already there" error, then somebody is probably already
doing dev on that cookbook in that version. You will want to coordinate with
whoever is doing that to prevent yourself from stepping on the other person's
toes. From that point on, you will need to force updates to your cookbook under
development:

```shell
knife block use <env>
berks upload identity-jenkins --force
```

Then you'll want to run chef-client on the hosts where the cookbook will take
effect:

```shell
knife block use <env>
knife ssh "name:*tf" "sudo chef-client" -x ubuntu -a ipaddress
```

In theory jenkins can do this.  See
https://github.com/18F/identity-private/issues/1317 for discussion.

## 7. Create FISMA AMI

We deploy a specifically created FISMA compliant AMI.  You can find the current
AMI
[here](https://github.com/18F/identity-devops/blob/90077bac679c2f0936260c5368cea95d1b38011f/env/env.sh.example#L28),
or pinned in the [#identity-devops](https://gsa-tts.slack.com/) channel.

To create secure [FISMA AMIs](https://github.com/fisma-ready/ubuntu-lts/tree/jjg/feature/ubuntu-1604-support), run:

```shell
git clone https://github.com/fisma-ready/ubuntu-lts
cd ubuntu-lts/
git checkout jjg/feature/ubuntu-1604-support
```

Follow [these
instructions](https://github.com/fisma-ready/ubuntu-lts/tree/jjg/feature/ubuntu-1604-support)
and update the AMI ID in slack and in the environment configuration.

## 8. Create a login.gov base AMI

This is not currently done for our deployments as far as I know, but is a first
step towards https://github.com/18F/identity-private/issues/1942.

XXX(sverch): I don't know if this actually works.

Make sure you have the packer variables set in env.sh

```
packer build packer/base-image.json
```

Take the AMI that resulted from that build and plug it into the TF_VAR_ami_id variable in env.sh

## 9. Manual Lockdown

The first time you deploy everything, you'll have to go manually lock down a couple of things:

* Port 22 on the chef-server. Do the last couple of steps that are commented out in the chef-server instance launch:

```
#  # lock the fw down so that we can only ssh in via the jumphost
#  provisioner "file" {
#    source = "chef-iptables.rules"
#    destination = "/etc/iptables/rules.v4"
#  }
#  provisioner "file" {
#    source = "chef-iptables6.rules"
#    destination = "/etc/iptables/rules.v6"
#  }
#  provisioner "local-exec" {
#    command = "ssh -o StrictHostKeyChecking=no ubuntu@${aws_instance.chef.public_ip} 'sudo aptitude install iptables-persistent'"
#  }

```

* Disallow ubuntu user from non-localhost locations on the jumphost. To do this, you will need to set the `default['login_dot_gov']['lockdown']` attribute to be true, and then chef-client on the bastion host.
* Do a chef-client on the chef-server to get it logging: `chef-client -r 'role[base]'`
* Enable ELK: `knife node run_list add elk.<env> 'recipe[identity-elk]' ; ssh elk sudo chef-client`

## 10. Jumphost SSH-Agent and Proxy Forwarding

There is an ssh jumphost set up now that we must use for all things. No direct ssh access is allowed to anything but the jumphost, and all internal services (ELK/Jenkins for now) must be accessed through the jumphost.

To use the jumpbox services, you will probably want to do two things:

* Forward your ssh-agent to the jumphost when you ssh in so you can ssh around inside.
* Forward a proxy port to the jumphost when you ssh in so you can use a web browser on internal services.

### 10.1. Helper Scripts for Common Workflows

These scripts rely on having your username set up as a default in `~/.ssh/config` for *all* jumphosts, like so:

```
# ~/.ssh/config
Host jumphost.prod.login.gov
       User zmargolis
       PKCS11Provider /usr/local/lib/pkcs11/opensc-pkcs11.so

Host jumphost.int.login.gov
       User zmargolis

# etc etc
```

#### 10.1.1 `./bin/ssh.sh`

Opens an SSH session on a particular host, defaults to `idp1-0`

```
$ ./bin/ssh.sh int
# ...
ubuntu@idp:~$
```

#### 10.1.2 `./bin/elk.sh`

Opens an SSH tunnel and forwards a port to proxy Kibana/ElasticSearch, it will open a web browser to the port it proxies.

```
$ ./bin/elk.sh int
```

#### 10.1.2 `./bin/jenkins.sh`

Ditto the `elk.sh` script but for Jenkins

```
$ ./bin/jenkins.sh int
```

#### 10.1.3 `./bin/rails-console.sh`

Opens an Rails console

```
$ ./bin/ssh.sh int
# ...
irb(main):001:0>
```

### 10.2. Manual SSH Jumping

You can do this with one command:

```
ssh -L3128:localhost:3128 -A <username>@jumphost.<env>.login.gov

```

Then, while that ssh session is active, any ssh keys that you are using in your ssh-agent (check with 'ssh-add -l') should be available on the jumphost, and you can set your browser up to route requests to *login.gov.internal to the proxy port. I will leave that as an exercise for the reader, as every browser has it's own way of doing that.

You can download Firefox and have it route all protocols over that proxied port. So when you want to get inside the environment, you can just use Firefox.

To set up Firefox:

1. Open your browser and click **Preferences** on the top left corner.
2. Go to **Advanced**, then the **Network** tab, then click **settings...** next to **Connections**
3. Click **Manual Proxy Configuration** then fill *localhost* next to **HTTP Proxy** and *3128* next to **Port**
4. Check **Use this proxy server for all protocols**

Click OK and restart your browser.

## 11. Other Miscellaneous Configurations

### 11.1 Elastic Search

Currently, bootstrap of ES is not perfect. If you are starting up a new cluster, you may need to log into the ES nodes and do this:

* On all ES nodes, log in and do a chef-client run to make sure that everybody has everybody else's certs.
* On all nodes that are not es0 (es1, es2, etc), log in and do this:

```
service elasticsearch stop
cd /var/lib/elasticsearch/
rm -rf nodes
chef-client

```

This will make sure that all the ES nodes are in sync. To test to make sure that ES is happy, this command should have output like this (2 node cluster in this example, note number_of_nodes and status):

```
root@es1:/var/lib/elasticsearch# curl -k https://es1.login.gov.internal:9200/_cluster/health?pretty=true
{
  "cluster_name" : "elasticsearch",
  "status" : "green",
  "timed_out" : false,
  "number_of_nodes" : 2,
  "number_of_data_nodes" : 2,
  "active_primary_shards" : 2,
  "active_shards" : 4,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 0,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 100.0
}
root@es1:/var/lib/elasticsearch#

```

Orchestration is tricky, and this is just a one-time thing for a new environment, so for now, we will just do this by hand.

### 11.2 CloudTrail

If this is the first environment you are spinning up, you will need to turn spin up the centralized cloudtrail bucket. Here is how:

```
./deploy apply terraform-cloudtrail

```

You may need to edit the terraform-cloudtrail/main.tf file to add in additional elk roles as you add environments so that they can access the bucket too.

Also! There seems to be some sort of incompatibility between the temporary data files of different versions of the plugins. If you are getting cloudtrail log errors, you may have to do this:

```
rm -rf /var/lib/logstash/*

```

This should clean out the incompatible files. We have also seen some strange schema/index issues that you can clear out if you delete the indexes and start over. This is a sort of nuclear option, as it deletes all logs currently indexed in the system. As we get a greater operational understanding of the magic of elasticsearch/logstash, we expect this problem to become more apparent so that we can devise a real fix. Here is how to do that:

```
curl -k -X DELETE https://es.login.gov.internal:9200/logstash-*

```

You may also have to go into kibana and tell it to refresh it's index pattern if it has the old one.`https://elk.login.gov.internal:8443/app/kibana#/management/kibana/indices/logstash-*` Then click on the orange button that has the two arrows circling around to Refresh the Field List.

### 11.3 Jenkins

#### 11.3.1 Jenkins Users and Admins

Jenkins will need to be set up too!

Admins and users for jenkins can be set up by editing the attributes in the environment:

```
default['identity-jenkins']['users'] = ['username','username2']
default['identity-jenkins']['admins'] = ['admin1','admin2']

```

A chef-client run will make sure that all of those things get applied.

#### 11.3.2 Chef Jenkins Key

On the chef-server, get the /root/jenkins.pem key. This is used for 'berks apply' and other berkshelf stuff. You will need to create a chef identity with this in it.

As a jenkins admin user, from the top level of the jenkins UI, go to "Manage Jenkins", then click on "Configure System", then set up "Chef Identity Management". Add the key in for the "jenkins" user from chef. This should work for the knife.rb:

```
current_dir = File.dirname(__FILE__)
log_level                :info
log_location             STDOUT
node_name                "jenkins"
client_key               "#{current_dir}/user.pem"
chef_server_url          "https://chef.login.gov.internal/organizations/login-dev"
cookbook_path            ["#{current_dir}/../kitchen/cookbooks"]

```

I would love to make this automatically configured too, but it stores these things as secrets, which means that they are encrypted on a host-by-host basis, so there's no good way to template-ize them that I know of.

#### 11.3.3 Jenkins/ELK Password Hash

You will also need to set up password hashes in the users databag if they haven't already been set up:

```
$ htpasswd -c /tmp/htpasswd username
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

#### 11.3.4 Jenkins Usage

* Make sure you are either in the GSA network (VPN or office), or are otherwise in the allowed IP whitelist.
* Go to the jenkins URL you got form terraform.
* Log in using your username/password from the users databag.
* Run the deploy stack job.
  * Input the gitref that you want to use to deploy the code. This can be a tag or a branch.
  * If infrastructure needs to change, that build will fail. Contact a devops person to ensure that gets pushed out before deploy. Someday we hope to make the AWS keys non-readonly so that jenkins can push infrastructure too, but that requires a lot of scrutiny, so we are avoiding that for now.
  * If the infrastructure doesn't need changing, it will push out the code too.
* Enjoy!

### 11.5. Deploying the application

In the past, Capistrano could be used for deployments, but I believe we are moving past that.

Here are the new ways to deploy code:

- [Using Chef (partially manual)](https://github.com/18F/identity-private/wiki/Operations:-Deploy-Application-Code)
- [Using Jenkins](https://github.com/18F/identity-private/wiki/Operations:--Deploy-Application-Code-with-Jenkins)

#### 11.5.1. App Control/Config with Rake Tasks

The `identity-devops` repo includes a
[Rakefile](https://github.com/18F/identity-devops/blob/44e86285ba1ffed2cc063fea5397c779ab2d2e62/Rakefile)
with some smoke tests for the application.

`rake help` - shows available help

`rake test` - runs entire test suite

`rake login:check_app_yml_keys` - validates current application.yml configuration templates against the IdP
