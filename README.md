# Login.gov Infrastructure Repository

This repository contains infrastructure configurations for the [identity-*](https://github.com/18F/identity-private) projects as well as instructions on how to build  

an environment/Virtual Private Cloud(VPC) using [Terraform](https://www.terraform.io/). It is recommended that you  

  familiarize yourself with the [Terraform CLI](https://www.terraform.io/docs/commands/), especially `plan` , `apply`, and `destroy` commands. 

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [1.  Required Tools Setup and Initial Terraform Run](#1--required-tools-setup-and-initial-terraform-run)
  - [1.1 Setup Prerequisite Tools](#11-setup-prerequisite-tools)
  - [1.2 Create FISMA AMI(Optional)](#12-create-fisma-amioptional)
  - [1.3 Create Environmental Variables File](#13-create-environmental-variables-file)
  - [1.4 Add Key to SSH-Agent](#14-add-key-to-ssh-agent)
  - [1.5 Add Required Local Files](#15-add-required-local-files)
  - [1.6 Initial Terraform Run](#16-initial-terraform-run)
- [2.  Chef Server Setup and Final Terraform Run](#2--chef-server-setup-and-final-terraform-run)
  - [2.1 Find Jumphost's Public IP](#21-find-jumphosts-public-ip)
  - [2.2 Setup Knife](#22-setup-knife)
    - [2.2.1 Verify Provisioner-created Files](#221-verify-provisioner-created-files)
    - [2.2.2 Upload .Chef and .Env to Jumphost](#222-upload-chef-and-env-to-jumphost)
    - [2.2.3 Create knife.rb](#223-create-kniferb)
    - [2.2.4 Clone Identity-Devops Repo  and Upload Databags(In Progress)](#224-clone-identity-devops-repo--and-upload-databagsin-progress)
    - [2.2.5 Create Databags](#225-create-databags)
  - [2.3 Create a login.gov base AMI(Optional)](#23-create-a-logingov-base-amioptional)
  - [2.4 Final Terraform Run](#24-final-terraform-run)
- [3. Jumphost Configuration and Common Usage Patterns](#3-jumphost-configuration-and-common-usage-patterns)
  - [3.1 Manual Lockdown](#31-manual-lockdown)
  - [3.2. Jumphost SSH-Agent and Proxy Forwarding](#32-jumphost-ssh-agent-and-proxy-forwarding)
  - [3.3 Using Chef](#33-using-chef)
    - [3.3.1 Moving Chef Credentials(knife, databag keys etc.) to The Jumphost](#331-moving-chef-credentialsknife-databag-keys-etc-to-the-jumphost)
    - [3.3.2 Creating Your User in the Chef Server(Optional)](#332-creating-your-user-in-the-chef-serveroptional)
  - [3.4 Using Capistrano](#34-using-capistrano)
  - [3.5 Using Terraform(Optional)](#35-using-terraformoptional)
- [4. Other Miscellaneous Configurations](#4-other-miscellaneous-configurations)
  - [4.1 Elastic Search](#41-elastic-search)
  - [4.2 CloudTrail](#42-cloudtrail)
  - [4.3 Jenkins](#43-jenkins)
    - [4.3.1 Jenkins Users and Admins](#431-jenkins-users-and-admins)
    - [4.3.2 Chef Jenkins Key](#432-chef-jenkins-key)
    - [4.3.3 Jenkins/ELK Password Hash](#433-jenkinselk-password-hash)
    - [4.3.4 Jenkins Usage](#434-jenkins-usage)
- [5. Release Process](#5-release-process)
  - [5.1 Infrastructure](#51-infrastructure)
  - [5.2 App Control/Config with Rake Tasks](#52-app-controlconfig-with-rake-tasks)
  - [5.3 Cookbook Changes](#53-cookbook-changes)
    - [5.3.1 Real Releases](#531-real-releases)
    - [5.3.2 Cookbook Development](#532-cookbook-development)
    - [5.3.3. (Un)Encrypted Databag Changes](#533-unencrypted-databag-changes)
    - [5.3.4 Code Changes](#534-code-changes)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## 1.  Required Tools Setup and Initial Terraform Run

### 1.1 Setup Prerequisite Tools

Install [Homebrew](https://brew.sh) (Ignore this step if you have already run the  [laptop script](https://github.com/18F/laptop) ).

```she
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

Install  [AWS CLI](https://aws.amazon.com/cli/)  in order to manage services from the command line.

``` shell
brew install awscli
```

Then, configure AWS by running `aws configure`. For `Default region name` use `us-east-1` if you are in 18f-sandbox, otherwise use `us-west-2`.

```shell
% aws configure
AWS Access Key ID [****************]: 
AWS Secret Access Key [****************]: 
Default region name [us-west-2]:
```

Finally, try getting a list of all available S3 buckets by running `aws s3 ls` You should be able to see something like this, in return:

```shell
% aws s3 ls
2017-03-07 12:26:08 login-<env>-secrets
2017-03-16 11:04:48 login-gov-cloudtrail-xxxx
2017-03-17 15:02:03 login-gov-<env>-logs
2017-03-17 15:02:01 login-gov-<env>-secrets
```

Install [ChefDK](https://downloads.chef.io/chefdk)

```shell
brew install Caskroom/cask/chefdk
```

Install [Terraform CLI](https://www.terraform.io/docs/commands/) 

``` shell
brew install terraform
```

### 1.2 Create FISMA AMI(Optional) 

** **Skip this step if there is an already built [AMI](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) (ask or look at pinned items in the [#identity-devops](https://gsa-tts.slack.com/) channel )** **

Create Secure [FISMA AMIs](https://github.com/fisma-ready/ubuntu-lts/tree/jjg/feature/ubuntu-1604-support)

```shell
git clone https://github.com/fisma-ready/ubuntu-lts
cd ubuntu-lts/
git checkout jjg/feature/ubuntu-1604-support
```

Follow [these instructions](https://github.com/fisma-ready/ubuntu-lts/tree/jjg/feature/ubuntu-1604-support) and use the generated AMI in the next step.

### 1.3 Create Environmental Variables File

`<env>.sh` will be used by Terraform to source environmental variables during `apply`/`plan`/`destroy` .

First, make a copy of `env.sh.example` and fill in the missing details for your specific env:

`<env>` is `dev/test/prod/demo/etc` 

``` shell
# cd into the identity-devops/env directory
cd path/to/identity-devops/env

# then create your env variables file  
cp env.sh.example <env>.sh
```

Edit `<env.sh>` by filling in all the required values.Then, source it

``` shell
source <env>.sh
```

There will be some details  that you will not be able to fill out, like subnet/AMI id, chef server,  etc. Those values will be supplied by terraform later and used in [Chef Server Setup and Final Terraform Run](#2--chef-server-setup-and-final-terraform-run).  

Common errors:

* **Verify that you have sourced the right environment**  before you `apply` . It is recommended that you quit and restart your shell so that the old env variables aren't there. You should *only* have the TF vars set that are in that env.sh (in this case `dev.sh`), not any others.

  ```shell
  echo $TF_VAR_env_name
  ```

* **Verify that all your paths are correct**   for keys such as `login-dev-us-west.pem` (should be under `~/.ssh`) 

### 1.4 Add Key to SSH-Agent

You need to add the value of `TF_VAR_key_name` to your ssh-agent, otherwise ssh handshake will fail. For `identity-devops` , it is `login-dev-us-west-2.pem`.

```shell
ssh-add ~/.ssh/login-dev-us-west-2.pem
```



### 1.5 Add Required Local Files

Before you run terraform you will need to have the TLS certificate, chain, and private key used for that env. Additionally you will also need a copy of the latest Nessus/Nessus Manager dpkg installer. This can be downloaded from [https://support.tenable.com/](https://support.tenable.com/) or copied from another teammate.

The certificates need to be named using the following scheme:

```
-rw-r-----  1 jjg  staff   1834 Jan 27 18:25 staging-cert.pem
-rw-r-----  1 jjg  staff   1647 Jan 27 18:25 staging-chain.pem
-rw-r-----  1 jjg  staff   1704 Jan 27 18:25 staging-key.pem
-rw-r-----  1 jjg  staff  22611 Jan 30 21:49 staging_app_etc_letsencrypt.tbz
-rw-r-----  1 jjg  staff  10562 Jan 29 13:34 staging_etc_letsencrypt.tbz
```



Note the presence of the tar archives. Those can be used so that the lets_encrypt resource in the login_dot_gov cookbook doesn't try to generate new certs. We can eventually remove that code since the cert is uploaded to the ALB and we can use self-signed certs on the app hosts. Furthermore, we can use the ACME terraform provider to more easily generate and renew certs going forward.

The Nessus/Nessus Manager dpkg is expected to be located in the root of the project folder:

```
/Nessus-6.10.0-ubuntu1110_amd64.deb
```



### 1.6 Initial Terraform Run

First, Plan your execution by running

``` shell
./deploy plan terraform-app
```

Scan the plan output to see if everything looks as intended.

Then apply it

```shell
./deploy apply terraform-app
```

`Terraform apply` should create a chef-server, but will fail to deploy all the other services, because they require chef to be fully set up.Terraform will say that it couldn't find your user in the users databag  and give you the output below. 

```shell
Error applying plan:

1 error(s) occurred:

* Command "sudo chef-client -j \"/etc/chef/first-boot.json\" -E \"qa\"" exited with non-zero exit status: 1

Terraform does not automatically rollback in the face of errors.
Instead, your Terraform state file has been partially updated with
any resources that successfully completed. Please address the error
above and apply again to incrementally change your infrastructure.
```

Otherwise, here are some other common errors:

* `SSH handshake failure` : make sure you added `login-dev-us-west-2.pem` to your ssh-agent
* `TCP handshake failure`: make sure you are on the GSA VPN or Network/Cidr block.




## 2.  Chef Server Setup and Final Terraform Run

### 2.1 Find Jumphost's Public IP

So far, the only thing  that was completely built is the chef-server. The jumphost dns name(i.e. `jumphost.<env>.login.gov`)  will be applied towards the end of this final Terraform apply.

Due to the restrictions of our [Security Groups]() and [Network Access Control Lists](), you need to ssh into the jumphost to be able to  interact with other machines in the same cluster/env (such as the chef-server, idp/app hosts, elk etc. ).

You can obtain the `Public IP` address of the jumphost by either:

* Navigating to the [AWS Management Console]() and searching for `jumphost-<env>` under Services/EC2

  or

* Using the AWS CLI

  ```shell
  # replace <env> 
  aws ec2 describe-instances --region us-west-2 | grep -A 20 -B 90 -i <env>_jumphost | grep PublicIp  
  ```

Write it somewhere(since we will be using it in the next sections).

### 2.2 Setup Knife

#### 2.2.1 Verify Provisioner-created Files

[Knife](https://docs.chef.io/knife.html) is  a command-line tool that provides an interface between a local chef-repo and the Chef server. 

The [Chef Provisioner](https://github.com/18F/identity-devops/blob/master/terraform-app/chef.tf#L69) should have created several files in your `~/.chef` directory. Check and make sure you have these three files:

* `yourusername-<env>.pem`
* `<env>-login-dev-validator.pem`
* `knife-<env>.rb` 
* `<env>-databag.key`

#### 2.2.2 Upload .Chef and .Env to Jumphost

You will need to copy your knife config and keys to the jumphost, check out the identity-devops repo, and execute all your chef/knife/berkshelf commands there.

There's a handy script `chefmove.sh` in the `bin` directory. 

It takes two arguments: your username and the jumphost Public DNS name. For the `dev` environment, you would run `./chefmove.sh dev jumphost.dev.login.gov` 

First, try `ssh  <yourusername>@jumphost.<env>.login.gov` . if you can ssh just fine, then yay! 

If you get an error that `jumphost.<env>.login.gov` isn't a valid Public DNS name, then that means the jumphost hasn't been fully built and you will need to use its Public IP instead.

At this stage, **you will need to use `ubuntu` as your username for now** , since your user hasn't been updated in the `users` databag yet. 

Then,

```shell
ssh ubuntu@<jumphost_public_ip_address> 
```

If you ssh successfully then, come back to your local machine and  upload your `~/.chef`  and `~/.env` 

```shell
# cd into identity-devops
# run the following command
./chefmove.sh ubuntu <jumphost_ip>
```

Make sure to read through `chefmove.sh` and verify that all the paths and names are correct. 

#### 2.2.3 Create knife.rb

ssh into the jumphost then rename `knife-<env>.rb` to `knife.rb` 

```shel
mv knife-<env>.rb knife.rb
```

edit your `knife.rb` to look like this(or create it if it doesn't exist):

```ruby
log_level                :info
log_location             STDOUT
node_name                '<yourusername>'
client_key               '/Path/to/.chef/yourusername-<env>.pem'
validation_client_name   '<env>-login-dev-validator'
validation_key           '/Path/to/.chef/<env>-login-dev-validator.pem'
chef_server_url          'https://chef.login.gov.internal/organizations/login-dev'
syntax_check_cache_path  '/Path/to/.chef/syntax_check_cache'
cookbook_path [ './kitchen/cookbooks' ]
ssl_verify_mode          :verify_none

```



If all the files in section **2.2.1** exists and have proper paths, then you should be able to `knife` to the chef-server from your jumphost.

try `knife node list` and then you should be able to get a list back of all the nodes in your env/VPC:

```shell
ubuntu@jumphost:~$ knife node list
app.jp
chef.jp
elk.jp
es0.jp
es1.jp
idp1.0.jp
idp2.0.jp
jenkins.jp
jumphost.jp
worker.jp
```



#### 2.2.4 Clone Identity-Devops Repo  and Upload Databags(In Progress)

#### 2.2.5 Create Databags 

This will create the databags that our other cookbooks need to run. You will probably want to go through all the XXXes in the knife data bag edit step.

First, create the **encrypted**  `config` databag used by the app/idp hosts.

```
openssl rand -base64 2048 | tr -d '\r\n' > ~/.chef/<env>-databag.key
knife block use <env>
knife data bag create config --secret-file ~/.chef/<env>-databag.key
knife data bag from file config ./template_config_dbag.json --secret-file ~/.chef/<env>-databag.key
knife data bag edit config app --secret-file ~/.chef/<env>-databag.key
```

Once it's all set up, add this line to your knife block setup:

```
echo "knife[:secret_file] =    '/Users/yourusername/.chef/<env>-databag.key'" >> /Users/<yourusername>/.chef/knife-<env>.rb
```



Then, create the **unencrypted** `users` databag to add your users(and other in identity-devops) to the chef-server.

```shell
knife data bag create users
cd kitchen/data_bags
for user in users; do knife data from file users $user; done

```

Finally, verify that your user was uploaded 

`knife data bag show users <yourusername>`

### 2.3 Create a login.gov base AMI(Optional)

This step is not required, but it will save you some time because your app/worker hosts will not need to build ruby and install gems, etc.

Make sure you have the packer variables set in env.sh

```
packer build  packer/base-image.json

```

Take the AMI that resulted from that build and plug it into the TF_VAR_ami_id variable in env.sh

I may have forgotten something here. You may also need to get some variables from terraform and plug them in to get this to work.

### 2.4 Final Terraform Run

From your local machine/laptop run 

```
./deploy apply terraform-app

```

This should launch all of the ELK/jenkins/app/worker hosts which were needing chef to launch.

If you get a successful run, you should get a few URLs which you can use to access the various services

```shell
Apply complete! Resources: 13 added, 0 changed, 1 destroyed.

The state of your infrastructure has been saved to the path
below. This state is required to modify and destroy your
2017/01/20 11:52:23 [DEBUG] plugin: waiting for all plugin processes to complete...
infrastructure, so keep it safe. To inspect the complete state
use the `terraform show` command.

State path: .terraform/terraform.tfstate

Outputs:

app_eip = xx.xx.xx.xx
aws_app_subnet_id = SUBNET_ID=subnet-xxxxxxxxxx
aws_db_address = postgres.login.gov.internal
aws_elasticache_cluster_address = redis.login.gov.internal
aws_sg_id = SECURITY_GROUP_ID=sg-xxxxxx
aws_vpc_id = VPC_ID=vpc-xxxxxxx
chef-eip = xx.xx.xx.xx
elk = https://xx.xx.xx.xx:8443/
elk_ip = xx.xx.xx.xx
env_name = qa
idp_db_address = idp-postgres.login.gov.internal
idp_eip = xx.xx.xx.xx
idp_worker_ip = xx.xx.xx.xx
jenkins = https://xx.xx.xx.xx:8443/
jenkins_ip = xx.xx.xx.xx
jumphost-eip = xx.xx.xx.xx
```



## 3. Jumphost Configuration and Common Usage Patterns

### 3.1 Manual Lockdown

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

### 3.2. Jumphost SSH-Agent and Proxy Forwarding

There is an ssh jumphost set up now that we must use for all things. No direct ssh access is allowed to anything but the jumphost, and all internal services (ELK/Jenkins for now) must be accessed through the jumphost.

To use the jumpbox services, you will probably want to do two things:

* Forward your ssh-agent to the jumphost when you ssh in so you can ssh around inside.
* Forward a proxy port to the jumphost when you ssh in so you can use a web browser on internal services.

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

### 3.3 Using Chef 

#### 3.3.1 Moving Chef Credentials(knife, databag keys etc.) to The Jumphost 

You will need to copy your knife config and keys to the jumphost, check out the identity-devops repo, and execute all your chef/knife/berkshelf commands there. See section **2.2.3**

It is hoped that this use case will slowly go away as we get more stuff moved into jenkins. 

#### 3.3.2 Creating Your User in the Chef Server(Optional)

This should have been done automatically by Terraform. If not:

First, verify that your username and its associated access rights(sudo,adm, etc) and public PIV key exist in the *users databag*. You can get someone in the DevOps team to verify this for you.

After your *users databag* item exists:

* **Option 1(Using a script):**

Run the `createchefclient.sh` located in the `bin` directory of this repo. It takes the Chef server's Private IP address or hostname as an argument.

`./createchefclient.sh login-chef-<env>`

Make sure to update the paths to correspond to where you uploaded your *.chef* directory.

* **Option 2(Manually):**

1. ssh into the Chef server from the jumphost using the Chef server's private IP. Then, run:

```shell
sudo chef-server-ctl user-create <username> <FirstName> <LastName> <FirstName>.<LastName>@gsa.gov <Password>
```

2. copy the generated private key into your `<username>-<env>.pem` located under the `/.chef` dir in the jumphost.
3. Add yourself to the admin group.

```shell
 sudo chef-server-ctl org-user-add login-dev <username> --admin
```

4. Make sure everything ran correctly.

```shell
 sudo chef-server-ctl user-show <username> 
 
```

 ### 3.4 Using Capistrano 

You will need to check out your source code on the jumphost boxes and do your deploys from there. This definitely needs your ssh-agent forwarded in to work.

### 3.5 Using Terraform(Optional) 

Just use Terraform from your local machine to save time. 

If you still want to use it in the jumphost, you'll need to get all your env vars set over there on the jumphost properly too. You should copy your env file over there and perhaps make it a part of your .bash_profile, and you should put this in your .ssh/config so that your AWS keys are never copied over there, yet you can use them:

```shell\
Host jumphost.<env>.login.gov
	SendEnv AWS_*
```



## 4. Other Miscellaneous Configurations

### 4.1 Elastic Search

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

### 4.2 CloudTrail

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

### 4.3 Jenkins

#### 4.3.1 Jenkins Users and Admins

Jenkins will need to be set up too!

Admins and users for jenkins can be set up by editing the attributes in the environment:

```
default['identity-jenkins']['users'] = ['username','username2']
default['identity-jenkins']['admins'] = ['admin1','admin2']

```

A chef-client run will make sure that all of those things get applied.

#### 4.3.2 Chef Jenkins Key

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

#### 4.3.3 Jenkins/ELK Password Hash

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

#### 4.3.4 Jenkins Usage

* Make sure you are either in the GSA network (VPN or office), or are otherwise in the allowed IP whitelist.
* Go to the jenkins URL you got form terraform.
* Log in using your username/password from the users databag.
* Run the deploy stack job.
  * Input the gitref that you want to use to deploy the code. This can be a tag or a branch.
  * If infrastructure needs to change, that build will fail. Contact a devops person to ensure that gets pushed out before deploy. Someday we hope to make the AWS keys non-readonly so that jenkins can push infrastructure too, but that requires a lot of scrutiny, so we are avoiding that for now.
  * If the infrastructure doesn't need changing, it will push out the code too.
* Enjoy!

## 5. Release Process

### 5.1 Infrastructure

If the 'terraform' jenkins job indicates that infrastructure changes need to happen, then you will need to push them out by hand for now, because we don't really want the jenkins node to be able to destroy all our nodes. :-)

Check the `terraform-app` plan against the current state of that environment.

```
./deploy plan terraform-app

```

The environment defaults to `tf` which is a highly volatile env meant for testing out new terraform configs. We can remove that env and change the default to `dev` once the churn slows down.

Apply any changes to the `tf` env using the terraform-app plan

```
./deploy apply terraform-app

```

Destroy all resources in an env

```
./deploy destroy terraform-app

```

Modify the `TF_VAR_env_name` to work with the other environments (`dev`, `qa`, `pt`, `staging`, `dm`, `production`)

### 5.2 App Control/Config with Rake Tasks

`rake help` - shows available help

`rake test` - runs entire test suite

`rake login:check_app_yml_keys` - validates current application.yml configuration templates against the IdP

### 5.3 Cookbook Changes

#### 5.3.1 Real Releases

For real releases, you will make sure your code is all checked in, and then create an identical gitref in the identity-devops and identity-idp repos.  We just need to be able to 'git checkout gitref' for it to work. Then, go to the jenkins server for the environment you want it to be deployed to and run the deploy stack job. Give it the gitref as a parameter, and it'll check everything out and make sure that it's pushed out there.

#### 5.3.2 Cookbook Development 

You could just do chef deploys using jenkins, but you can also iterate a bit faster if you push it out there by hand:

Probably most of the time, you'll just be pushing one cookbook up, so you can bump the cookbook version number and then do this:

```shell
berks
berks upload identity-jenkins 
berks apply <env>
```

If you get a "cookbook already there" error, then somebody is probably already doing dev on that cookbook in that version. You will want to coordinate with whoever is doing that to prevent yourself from stepping on the other person's toes. From that point on, you will need to force updates to your cookbook under development:

```shell
knife block use <env>
berks upload identity-jenkins --force 
```

Then you'll want to run chef-client on the hosts where the cookbook will take effect:

```shell
knife block use <env>
knife ssh "name:*tf" "sudo chef-client" -x ubuntu -a ipaddress
```

#### 5.3.3. (Un)Encrypted Databag Changes

```shell
knife data bag edit config app # knife[:secret-file] should be set in your knife.rb
```

#### 5.3.4 Code Changes

You probably should do deployments using jenkins, or you can probably still use capistrano. Capistrano may just go away in the future, though. For jenkins, just go to the jenkins UI and run the code job with the gitref that you want to deploy.

