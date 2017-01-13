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

#### Initial terraform run

This will build the chef-server and prepare it for you loading environment
config onto it.  Be aware that the first-time uploading of the chef-server
deb in the terraform-chefdata apply may take a while.

```
./deploy apply terraform-app
```

The deploy should create a chef-server, but will fail to deploy all the other services,
because they require chef to be fully set up.  This is fine, proceed to the next step.

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
the various services.  Yay!


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
* Go to https://ip.add.re.ss:8443/
* Log in using your username/password from the users databag.
* Run the deploy stack job. 
  * Input the gitref that you want to use to deploy the code.  This can be a tag or a branch.
  * If infrastructure needs to change, that build will fail.  Contact a devops person to ensure that gets pushed out before deploy.  Someday we hope to make the AWS keys non-readonly so that jenkins can push infrastructure too, but that requires a lot of scrutiny, so we are avoiding that for now.
  * If the infrastructure doesn't need changing, it will push out the code too. 
* Enjoy!
=======
XXX
=======
  * If the infrastructure doesn't need changing, it will push out the chef stuff and code too. 

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
