# login.gov Dev/Ops repository

<!-- MarkdownTOC -->

- Terraform
  - Initial Setup
- Release Process
  - Infrastructure
  - App control/config with Rake tasks
  - cookbook changes
  - encrypted databag changes
  - Code changes
- Notes

<!-- /MarkdownTOC -->


## Terraform

### Initial Setup

#### Install aws cli tools and ChefDK

```
brew install awscli
brew install Caskroom/cask/chefdk
brew install terraform
```

Configure (set the region to us-east-1 if you're using the 18f-sandbox account)

```
aws configure
```

Make sure that you can do an "aws s3 ls" and see stuff.

#### Create FISMA AMI

Create secure AMIs from https://github.com/fisma-ready/ubuntu-lts/tree/jjg/feature/ubuntu-1604-support

```
git clone https://github.com/fisma-ready/ubuntu-lts
cd ubuntu-lts/
git checkout jjg/feature/ubuntu-1604-support
```
follow instructions from https://github.com/fisma-ready/ubuntu-lts/tree/jjg/feature/ubuntu-1604-support, use the AMI generated in the next step.

#### Set up env.sh

```
cp env.sh.example env.sh
<edit env.sh>
. ./env.sh
```

There will be some stuff that you will not be able to fill out, like subnet/AMI id, chef
server, etc.  That will be supplied by terraform later on, so do what you can for now.

If you were ever using old environment variables, it might be useful to nuke your shell
and start over so that the old stuff isn't in there.  You should _only_ have the TF vars
set that are in that env.sh, not any others.

Make sure to add the key set in `TF_VAR_key_name` to your ssh-agent:

```
ssh-add /path/to/TF_VAR_key_name
```

#### Add required local files ####

Before you run terraform you will need to have the TLS certificate, chain, and private key used for
that env. Additionally you will also need a copy of the latest Nessus/Nessus Manager dpkg installer.
This can be downloaded from https://support.tenable.com/ or copied from another teammate.

The certificates need to be named using the following scheme:

```
-rw-r-----  1 jjg  staff   1834 Jan 27 18:25 staging-cert.pem
-rw-r-----  1 jjg  staff   1647 Jan 27 18:25 staging-chain.pem
-rw-r-----  1 jjg  staff   1704 Jan 27 18:25 staging-key.pem
-rw-r-----  1 jjg  staff  22611 Jan 30 21:49 staging_app_etc_letsencrypt.tbz
-rw-r-----  1 jjg  staff  10562 Jan 29 13:34 staging_etc_letsencrypt.tbz
```

Note the presence of the tar archives. Those can be used so that the lets_encrypt resource in the
login_dot_gov cookbook doesn't try to generate new certs. We can eventually remove that code since
the cert is uploaded to the ALB and we can use self-signed certs on the app hosts. Furthermore, we
can use the ACME terraform provider to more easily generate and renew certs going forward.

The Nessus/Nessus Manager dpkg is expected to be located in the root of the project folder:

```
/Nessus-6.10.0-ubuntu1110_amd64.deb
```

#### Initial terraform run

This will build the chef-server and prepare it for you loading environment
config onto it.  Be aware that the first-time uploading of the chef-server
deb in the terraform-chefdata apply may take a while.


```
./deploy apply terraform-app
```

The deploy should create a chef-server, but will fail to deploy all the other services,
because they require chef to be fully set up. If you receive 
[this expected output](https://gist.github.com/amoose/79c407c37969544e4e89f378f340e9a1) 
proceed to the next step.


#### Set up knife block

The provisioners should have created several files in your ~/.chef dir:
  * yourusername-env.pem
  * env-login-dev-validator.pem

These are used by knife block, so if you have problems with knife block, check them out to make sure they have data in them.

```
cd identity-devops # If you aren't already
bundle install
knife block new
```

Give inputs like this:
```
$ knife block new
This will create a new knife configuration file for you to use with knife-block
Please provide a friendly name for the new configuration file: <env>
Please enter the url to your Chef Server: https://ip.add.re.ss/organizations/login-dev
Please enter the name of the Chef client: <yourusername>
Please enter the validation clientname: [chef-validator] login-dev-validator
Please enter the location of the validation key: [/etc/chef-server/chef-validator.pem] ~/.chef/<env>-login-dev-validator.pem
Please enter the path to a chef repository (or leave blank): ./kitchen
*****

You must place your client key in:
  /Users/<yourusername>/.chef/<yourusername>-<env>.pem
Before running commands with Knife

*****

You must place your validation key in:
  /etc/chef-server/<env>-login-dev-validator.pem
Before generating instance data with Knife

*****
Configuration file written to /Users/<yourusername>/.chef/knife-<env>.rb
/Users/<yourusername>/.chef/knife-<env>.rb has been successfully created
The available chef servers are:
	* old
	* <env> [ Currently Selected ]
The knife configuration has been updated to use <env>
Berkshelf configuration for <env> not found
$ 
```

Turn off ssl verification by editing the resulting ~/.chef/knife-env.rb file:
```
echo 'ssl_verify_mode          :verify_none' >> /Users/<yourusername>/.chef/knife-<env>.rb
```

Now you can switch environments you are pointing at with "knife block use <env>".
BE CAREFUL THAT YOU ARE POINTING AT THE PROPER ENVIRONMENT BEFORE EDITING DATABAGS
AND DOING OTHER POTENTIALLY DESTRUCTIVE COMMANDS!

#### Create encrypted databag

This will create the encrypted databags that our other cookbooks need to run.
You will probably want to go through all the XXXes in the knife data bag edit step.

```
openssl rand -base64 2048 | tr -d '\r\n' > ~/.chef/<env>-databag.key
knife block use <env>
knife data bag create config --secret-file ~/.chef/<env>-databag.key
knife data bag from file config ./template_config_dbag.json --secret-file ~/.chef/<env>-databag.key
knife data bag edit config app --secret-file ~/.chef/<env>-databag.key
./usermove.sh old <env>
```

Once it's all set up, add this line to your knife block setup:
```
echo "knife[:secret_file] =    '/Users/yourusername/.chef/<env>-databag.key'" >> /Users/<yourusername>/.chef/knife-<env>.rb
```
This sets it up so that you should be able to edit the encrypted databag without having to
specify the secret file every time.

#### (Optional)  Create a login.gov base AMI

This step is not required, but it will save you some time because your app/worker hosts
will not need to build ruby and install gems, etc.

Make sure you have the packer variables set in env.sh
```
packer build  packer/base-image.json
```
Take the AMI that resulted from that build and plug it into the TF_VAR_ami_id variable in env.sh

I may have forgotten something here.  You may also need to get some variables from
terraform and plug them in to get this to work.

#### Final terraform run
```
./deploy apply terraform-app
```
This should launch all of the ELK/jenkins/app/worker hosts which were needing
chef to launch.

If you get a successful run, you should get a few URLs which you can use to access
the various services.
[The output should look like this](https://gist.github.com/amoose/eb473b09994329d5b19f8cb0cee0589c)
Yay!

#### Manual Lockdown/config

The first time you deploy everything, you'll have to go manually lock down a couple of things:
  * Port 22 on the chef-server.  Do the last couple of steps that are commented out in the chef-server instance launch:
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
  * Disallow ubuntu user from non-localhost locations on the jumphost.  To do this, you will need to set
    the ```default['login_dot_gov']['lockdown']``` attribute to be true, and then chef-client on the bastion host.   
  * Do a chef-client on the chef-server to get it logging: ```chef-client -r 'role[base]'```
  * Enable ELK:  ```knife node run_list add elk.<env> 'recipe[identity-elk]' ; ssh elk sudo chef-client```

#### Jumphost usage!  IMPORTANT!

There is an ssh jumphost set up now that we must use for all things.  No direct ssh access is
allowed to anything but the jumphost, and all internal services (ELK/Jenkins for now) must be
accessed through the jumphost.

To use the jumpbox services, you will probably want to do two things:
  * Forward your ssh-agent to the jumphost when you ssh in so you can ssh around inside.
  * Forward a proxy port to the jumphost when you ssh in so you can use a web browser on internal services.

You can do this with one command:
```
ssh -L3128:localhost:3128 -A <username>@jumphost.<env>.login.gov
```

Then, while that ssh session is active, any ssh keys that you are using in your ssh-agent
(check with 'ssh-add -l') should be available
on the jumphost, and you can set your browser up to route requests to *login.gov.internal to the proxy
port.  I will leave that as an exercise for the reader, as every browser has it's own way of doing that.

You can download Firefox and have it route all protocols over that proxied port.  So when you
want to get inside the environment, you can just use Firefox.

To set up Firefox:               
 1. Open your browser and click **Preferences** on the top left corner.              
 2. Go to **Advanced**, then  the **Network** tab, then click **settings...** next to **Connections**            
 3. Click **Manual Proxy Configuration** then fill _localhost_ next to **HTTP Proxy** and _3128_ next to **Port**          
 4. Check **Use this proxy server for all protocols**                    

Click OK and restart your browser.


#### Common Jumphost Usage Patterns:   

##### Chef      
###### **Moving Chef Credentials(knife, databag keys etc.) to The Jumphost** 
You will need to copy your knife config and keys to the jumphost, check out the identity-devops
repo,  and execute all your chef/knife/berkshelf commands there.               

You can use the `bin/chefmove.sh` script to move your _.chef_ and  checkout *identity-devops* from GitHub into the jumphost. It takes two arguments: _<env>_ and the correspond jumphost   
fqdn. E.g.: For the  `dev` environment, you would run `./chefmove.sh dev jumphost.dev.login.gov`.                       

It is hoped that this use case will slowly go away as we get more stuff moved into jenkins.         

###### **Creating your User in the Chef Server.**    

First, verify that your username and its associated access rights(sudo,adm, <env> etc) and public PIV key exist in the _users databag_. You can get someone in the DevOps team to verify this
for you.           

After your _users databag_ item exists:           

* **Option 1(Using a script):**            

Run the `createchefclient.sh` located in the `bin` directory of this repo. It takes the Chef server's Private IP address or hostname as an argument.        

`./createchefclient.sh login-chef-<env>`       

Make sure to update the paths to correspond to where you uploaded your _.chef_ directory.     

* **Option 2(Manually):**   
  
1.  ssh into the Chef server from the jumphost using the Chef server's private IP. Then, run:      

  ```
  sudo chef-server-ctl user-create <username> <FirstName> <LastName> <FirstName>.<LastName>@gsa.gov <Password>
  ```   


2.  copy the generated private key into your `<username>-<env>.pem` located under the `/.chef` dir in the jumphost.    

3.  Add yourself to the admin group.
 ```
  sudo chef-server-ctl org-user-add login-dev <username> --admin
  ```          

        

4. Make sure everything ran correctly.  
 ```       
  sudo chef-server-ctl user-show <username> 
  
  ```
       


##### capistrano stuff
You will need to check out your source code on the jumphost boxes and do your deploys from
there.  This definitely needs your ssh-agent forwarded in to work.

##### terraform stuff
After the initial terraform run and lockdown, you will need to run terraform from the jumphost.
This means you'll need to get all your env vars set over there on the jumphost properly too.
You should copy your env file over there and perhaps make it a part of your .bash_profile,
and you should put this in your .ssh/config so that your AWS keys are never copied over there,
yet you can use them:
```
Host jumphost.<env>.login.gov
	SendEnv AWS_*
```

#### Elasticsearch initial bootstrap fiddling

Currently, bootstrap of ES is not perfect.  If you are starting up a new cluster, you
may need to log into the ES nodes and do this:
  * On all ES nodes, log in and do a chef-client run to make sure that everybody has everybody else's certs.
  * On all nodes that are not es0 (es1, es2, etc), log in and do this:
```
service elasticsearch stop
cd /var/lib/elasticsearch/
rm -rf nodes
chef-client
```

This will make sure that all the ES nodes are in sync.  To test to make sure that
ES is happy, this command should have output like this (2 node cluster in this example, note number_of_nodes and status):
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

Orchestration is tricky,
and this is just a one-time thing for a new environment, so for now, we will just do this by hand.

#### Cloudtrail

If this is the first environment you are spinning up, you will need to turn spin
up the centralized cloudtrail bucket.  Here is how:
```
./deploy apply terraform-cloudtrail
```

You may need to edit the terraform-cloudtrail/main.tf file to add in additional
elk roles as you add environments so that they can access the bucket too.

Also!  There seems to be some sort of incompatibility between the temporary data files
of different versions of the plugins.  If you are getting cloudtrail log errors, you may
have to do this:
```
rm -rf /var/lib/logstash/*
```
This should clean out the incompatible files.  We have also seen some strange schema/index
issues that you can clear out if you delete the indexes and start over.  This is a sort of
nuclear option, as it deletes all logs currently indexed in the system.  As we get a greater
operational understanding of the magic of elasticsearch/logstash, we expect this problem
to become more apparent so that we can devise a real fix.  Here is how to do that:
```
curl -k -X DELETE https://es.login.gov.internal:9200/logstash-*
```

You may also have to go into kibana and tell it to refresh it's index pattern if it has
the old one.  ```https://elk.login.gov.internal:8443/app/kibana#/management/kibana/indices/logstash-*```
Then click on the orange button that has the two arrows circling around to Refresh the Field List.

#### DNS setup

If you have not set up DNS, or you need to make changes, then you will need to run this:
```
./deploy apply terraform-dns
```

Right now, it reads data from all of the tfstate files and updates dns for them.
So the various environments are hardcoded (or not) in the terraform-dns dir.
If you add more environments, you will need to copy and change one of those files
for your new environment, probably the variables.tf file too.

Eventually, I would like to make it so that jenkins can update the route53 zone,
and just make it so that the individual environments update this themselves, rather
than centralizing it, but we aren't quite there yet.

#### jenkins users and admins
Jenkins will need to be set up too!

Admins and users for jenkins can be set up by editing the attributes in the environment:
```
default['identity-jenkins']['users'] = ['username','username2']
default['identity-jenkins']['admins'] = ['admin1','admin2']
```

A chef-client run will make sure that all of those things get applied.

#### Chef jenkins key
On the chef-server, get the /root/jenkins.pem key.  This is used for 'berks apply'
and other berkshelf stuff.  You will need to create a chef identity with this in it.

As a jenkins admin user, from the top level of the jenkins UI, go to "Manage Jenkins", then
click on "Configure System", then set up "Chef Identity Management".  Add the key in for the "jenkins" user from chef.  This
should work for the knife.rb:
```
current_dir = File.dirname(__FILE__)
log_level                :info
log_location             STDOUT
node_name                "jenkins"
client_key               "#{current_dir}/user.pem"
chef_server_url          "https://chef.login.gov.internal/organizations/login-dev"
cookbook_path            ["#{current_dir}/../kitchen/cookbooks"]
```

I would love to make this automatically configured too, but it stores these things as secrets,
which means that they are encrypted on a host-by-host basis, so there's no good way to template-ize
them that I know of.

#### users databag
You will also need to set up password hashes in the users databag if they haven't already
been set up:
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

This password is what users will use to get into jenkins. 
This basic auth stuff can get replaced with SAML or LDAP or something
someday.

#### Jenkins Use

* Make sure you are either in the GSA network (VPN or office), or are otherwise in the allowed IP whitelist.
* Go to the jenkins URL you got form terraform.
* Log in using your username/password from the users databag.
* Run the deploy stack job. 
  * Input the gitref that you want to use to deploy the code.  This can be a tag or a branch.
  * If infrastructure needs to change, that build will fail.  Contact a devops person to ensure that gets pushed out before deploy.  Someday we hope to make the AWS keys non-readonly so that jenkins can push infrastructure too, but that requires a lot of scrutiny, so we are avoiding that for now.
  * If the infrastructure doesn't need changing, it will push out the code too. 
* Enjoy!

## Release Process

### Infrastructure

If the 'terraform' jenkins job indicates that infrastructure changes need to happen,
then you will need to push them out by hand for now, because we don't really want the
jenkins node to be able to destroy all our nodes.  :-)

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

### App control/config with Rake tasks

`rake help` - shows available help

`rake test` - runs entire test suite

`rake login:check_app_yml_keys` - validates current application.yml configuration templates against the IdP

### cookbook changes

#### Real Releases

For real releases, you will make sure your code is all checked in, and then create
an identical gitref in the identity-devops and
identity-idp repos.  Could be tags/branches.  Whatever.  We just need to be able to
'git checkout gitref' for it to work.  Then, go to the jenkins server for the environment
you want it to be deployed to and run the deploy stack job.  Give it the gitref as a
parameter, and it'll check everything out and make sure that it's pushed out there.

#### Cookbook development

You could just do chef deploys using jenkins, but you can also iterate a bit
faster if you push it out there by hand:

Probably most of the time, you'll just be pushing one cookbook up, so you can bump the
cookbook version number and then do this:
```
knife block use <env>
berks
berks upload identity-jenkins --ssl-verify=false
berks apply <env>
```

If you get a "cookbook already there" error, then somebody is probably already doing dev on
that cookbook in that version.  You will want to coordinate with whoever is doing that to
prevent yourself from stepping on the other person's toes.
From that point on, you will need to force updates to your cookbook under development:
```
knife block use <env>
berks upload identity-jenkins --force --ssl-verify=false
```

Then you'll want to run chef-client on the hosts where the cookbook will take effect:
```
knife block use <env>
knife ssh "name:*tf" "sudo chef-client" -x ubuntu -a cloud.public_ipv4
```

### encrypted databag changes
```
knife block use <env>
knife data bag edit config app
```

### Code changes

You probably should do deployments using jenkins, or you can probably still use capistrano.
Capistrano may just go away in the future, though.  For jenkins, just go to the jenkins
UI and run the code job with the gitref that you want to deploy.

## Notes

Have fun!!

Use the MarkdownTOC plugin for Atom or Sublime Text to automatically update the
ToC in this doc.

