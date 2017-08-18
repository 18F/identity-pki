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
- [7. Create FISMA AMI](#7-create-fisma-ami)
- [8. Create a login.gov base AMI](#8-create-a-logingov-base-ami)
- [9. Manual Lockdown](#9-manual-lockdown)
- [10. Other Miscellaneous Configurations](#10-other-miscellaneous-configurations)
  - [10.1 Elastic Search](#101-elastic-search)
  - [10.2 CloudTrail](#102-cloudtrail)
    - [Kibana default index pattern](#kibana-default-index-pattern)
  - [10.3 Jenkins](#103-jenkins)
    - [10.3.1 Jenkins Users and Admins](#1031-jenkins-users-and-admins)
    - [10.3.2 Chef Jenkins Key](#1032-chef-jenkins-key)
    - [10.3.3 Jenkins/ELK Password Hash](#1033-jenkinselk-password-hash)
    - [10.3.4 Jenkins Usage](#1034-jenkins-usage)
  - [10.5. Deploying the application](#105-deploying-the-application)
    - [10.5.1. App Control/Config with Rake Tasks](#1051-app-controlconfig-with-rake-tasks)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## 1. Introduction

This repository contains the base infrastructure for login.gov.

If you are new to this project, start here:

- [Contributing to identity-devops](contributing.md)
- [Testing identity-devops code](technical/testing.md)
- [Deploying identity-devops code](technical/deployment.md)
- [Structure of this Repository](structure-of-this-repository.md).
- [Infrastructure Architecture](technical/architecture.md).
- [Lifecycle of Custom Instances](technical/life-of-an-instance.md).

The rest of this page should document the process of setting up a new
environment from scratch, although the pages above have been updated more
recently than this one.

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
or
``` shell
brew upgrade awscli
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

Install [Terraform CLI](https://www.terraform.io/docs/commands/) and
[Terraform ACME Provider Plugin](https://github.com/paybyphone/terraform-provider-acme).

Most of our environments use terraform 0.8.8.
    - We are in the process of upgrading from 0.8.8, check back
      [here](https://github.com/18F/identity-private/issues/1877) for the status of that upgrade.

You can use `bin/brew-switch-terraform.sh` to manage installed versions of
Terraform and the Terraform ACME plugin. (This script relies on Homebrew and
only works on macOS.) There will be multiple versions of Terraform installed,
but only one will be symlinked onto your PATH at any given time. Run
`terraform --version` to see which one.

We use a Terraform plugin that adds an ACME provider used to generate our Let's
Encrypt TLS certificates. This will be installed automatically when you run
`bin/brew-switch-terraform.sh`.

Run the script to install and switch to Terraform 0.9.6. Follow the prompts
when it asks to create a `~/.terraformrc` to manage your ACME plugin:

```shell
bin/brew-switch-terraform.sh 0.9.6
```

Run the script to install and switch to Terraform 0.8.8:

```
bin/brew-switch-terraform.sh 0.8.8
```

The `deploy` script will enforce for each environment which versions of
Terraform have been tested on that environment. (See environment variables
discussion below.)

## 3. Environment Variables File

We currently use a lot of environment variables for configuration. These are
managed by scripts in
[identity-devops-private:/env/](https://github.com/18F/identity-devops-private/tree/master/env).
Do not source these scripts directly; they are used by the `deploy` and
`bootstrap.sh` scripts described below.

One thing you may have to change is `TF_VAR_app_sg_ssh_cidr_blocks` if you're not
on the internal GSA network.  You can set these in the environment-specific
file for your environment so it doesn't apply everywhere. See
https://github.com/18F/identity-private/issues/1769#issuecomment-290822192.

When you run `deploy` or `bootstrap`, it should clone
[identity-devops-private](https://github.com/18F/identity-devops-private) if
you haven't done so already. There are files in `identity-devops-private` that
automatically override the `base.sh` variables with environment-specific
values.

The `deploy` script will automatically `git pull` in `identity-devops-private`
to keep it up-to-date, since it's important to have the latest environment
configuration.

See [process-issue-tracking.md](./process-issue-tracking.md) for more
background on the repo layout. The [Environment variable
configuration](./process-issue-tracking.md#environment-variable-configuration)
section discusses this in detail.

See https://github.com/18F/identity-devops-private/issues/1 for more long-term
vision on how environment configuration should be handled.

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

When it calls the `deploy` script, it will also clone
`identity-devops-private`, which you can use to set variables that are unique
to your environment.

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

See [our Chef documentation](technical/chef.md).

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

## 10. Other Miscellaneous Configurations

### 10.1 Elastic Search

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

### 10.2 CloudTrail

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

#### Kibana default index pattern

If you're setting up a new ELK server for the first time, you will be prompted to create a default index pattern. Use `logstash-*` (the default) as the name, and `@timestamp` for the "Time-field name".

### 10.3 Jenkins

#### 10.3.1 Jenkins Users and Admins

Jenkins will need to be set up too!

Admins and users for jenkins can be set up by editing the attributes in the environment:

```
default['identity-jenkins']['users'] = ['username','username2']
default['identity-jenkins']['admins'] = ['admin1','admin2']

```

A chef-client run will make sure that all of those things get applied.

#### 10.3.2 Chef Jenkins Key

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

#### 10.3.3 Jenkins/ELK Password Hash

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

#### 10.3.4 Jenkins Usage

* Make sure you are either in the GSA network (VPN or office), or are otherwise in the allowed IP whitelist.
* Go to the jenkins URL you got form terraform.
* Log in using your username/password from the users databag.
* Run the deploy stack job.
  * Input the gitref that you want to use to deploy the code. This can be a tag or a branch.
  * If infrastructure needs to change, that build will fail. Contact a devops person to ensure that gets pushed out before deploy. Someday we hope to make the AWS keys non-readonly so that jenkins can push infrastructure too, but that requires a lot of scrutiny, so we are avoiding that for now.
  * If the infrastructure doesn't need changing, it will push out the code too.
* Enjoy!

### 10.5. Deploying the application

In the past, Capistrano could be used for deployments, but I believe we are moving past that.

Here are the new ways to deploy code:

- [Using Chef (partially manual)](https://github.com/18F/identity-private/wiki/Operations:-Deploy-Application-Code)
- [Using Jenkins](https://github.com/18F/identity-private/wiki/Operations:--Deploy-Application-Code-with-Jenkins)

#### 10.5.1. App Control/Config with Rake Tasks

The `identity-devops` repo includes a
[Rakefile](https://github.com/18F/identity-devops/blob/44e86285ba1ffed2cc063fea5397c779ab2d2e62/Rakefile)
with some smoke tests for the application.

`rake help` - shows available help

`rake test` - runs entire test suite

`rake login:check_app_yml_keys` - validates current application.yml configuration templates against the IdP
