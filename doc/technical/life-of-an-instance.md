# Life of an Instance

This page describes generically the lifecycle of AWS instances in the
infrastructure.  If you want to know more about specific instances, see the
[Architecture Documentation](architecture.md).

### Step 1: Create an Instance Role

```
# In identity-devops
echo "{\"name\":\"myfavoritecow\"}" >> kitchen/roles/myfavoritecow.json
```

Each instance in our infrastructure has a “role”.  Some examples are, “idp” for
our front of house identity provider servers that clients communicate with from
the outside, “worker” for the hosts that process background jobs including SMS
and email, and “elk” for the hosts that run logstash and kibana.

The role is not just a concept, it is explicitly defined as a Chef Role, which
is a collection of Chef Recipes (blocks of special purpose ruby code that
configure specific parts of an instance) and other Roles that together define
how the resulting instance will be configured.

This role is used both in our test framework and in our autoscaling group
configuration, as described below.  See the “kitchen/roles” directory in
identity-devops for the current roles we support.  Not all roles, for example
“role[base]”, correspond to an instance, but each instance should have a
corresponding role.

### Step 2: Add Integration Tests

```
# In identity-devops
cp -r nodes/jumphost/ nodes/myfavoritecow/
vim README.md
```

To do integration tests, we use the [Test
Kitchen](https://github.com/test-kitchen/test-kitchen) test framework with the
[ec2](https://github.com/test-kitchen/kitchen-ec2) provisioner.

This framework spins up an ec2 instance, uses the Berksfile (similar to a
Gemfile) to download all the cookbook (packaged collections of configuration
recipes) dependencies, copies the cookbooks to the running instance, and then
runs chef-zero (chef-client in local mode) with a run list of the node’s role to
apply the necessary recipes and configure the instance.

After the instance is fully configured, test kitchen then runs inspec (a
declarative rspec like verification tool) to check that the instance is
configured the way we expect it to be (all services installed properly and
running, etc.).  The framework then cleans up the instance it created.

All instance testing is done in a dedicated minimal “CI VPC” that only has the
base services needed by some of the integration tests, such as RDS and
Elasticache, and allows direct ssh access to all subnets to work around the fact
that test kitchen doesn’t support proxy commands.  The current CI VPC
configuration can be found
[here](https://github.com/18F/identity-devops-private/blob/master/env/ci.sh).

The currently supported tests are in the “nodes” directory of identity-devops.
Documentation for how to run these tests can be found [here](testing.md).

### Step 3: Add Terraform Autoscaling Configuration

```
# In identity-devops
sed -e 's/worker/myfavoritecow/g' terraform-app/worker-asg.tf >> terraform-app/myfavoritecow-asg.tf
echo "variable \"asg_myfavoritecow_desired\" { default = 0 }" >> terraform-app/variables.tf
```

The autoscaling deployment has two main pieces.  The first is the cloud-init
configuration that allows instances to self bootstrap, and the second is the set
of terraform resources that actually create the autoscaling group and launch
configuration in AWS.

#### Cloud-init and Bootstrapping

Cloud-init is a tool for performing initial bootstrap tasks on an instance.  You
configure cloud-init by encoding some scripts (or cloud-init YAML files) and
passing them into the “user data” attribute of the newly created instance.
Cloud init will iterate all these files and either run the scripts or apply the
configuration, depending on the type of each file.

We have some cloud-init scripts that download a specific version of
identity-devops and identity-devops-private, install chef-client, and run
chef-zero (chef-client in local mode) against those repositories.  These scripts
take the instance role, and set that in the run list of the initial chef-client
run.

What this means is that each instance can bootstrap itself with no human
intervention, so the configuration step is all automatic.

#### Terraform Configuration

The actual provisioning can be done using any of the provisioning interfaces
that AWS supports (the console, the CLI, the language SDKs, terraform).  In our
case, we use AWS Autoscaling groups, and configure them in terraform.

So to deploy an instance, run terraform to create the Autoscaling group and
launch configuration, passing in the proper cloud-init scripts.  Then, or in the
same step, set the number of requested instances to be something non zero.
Amazon will attempt to spin up a number of instances to meet that demand.

Here is an example of the terraform configuration needed to make this happen:
https://github.com/18F/identity-devops/blob/master/terraform-app/worker-asg.tf.

### Step 4: Deploy To An Environment

```
# In identity-devops-private
echo "export TF_VAR_asg_myfavoritecow_desired=2" >> env/mycowenv.sh

# In identity-devops
./deploy mycowenv myusername terraform-app plan # Check output!
./deploy mycowenv myusername terraform-app apply
```

By default, terraform only creates the autoscaling configuration, but does not
spin up any instances, so for each environment, the number of autoscaled
instances must be set explicitly in `identity-devops-private`.

After that, doing a terraform apply will raise the desired instance count which
will cause AWS to attempt to spin up that number of instances.  Any instances
that fail the health checks past the spin up grace period, will be destroyed by
AWS, and AWS will keep trying to spin up instances until it has a number of
healthy instances equal to the desired instance count.

### Step 5: R-e-c-y-c-l-e: Recycle Instances

```
asg-recycle.sh mycowenv myfavoritecow
```

All updates (AMIs, Configuration, Application Code) are done by recycling the
instances.

To do this, double the desired number of instances, and then when the new
instances are up and healthy, spin back down to the normal amount and AWS will
destroy the oldest ones.  There is a script to do this here:
https://github.com/18F/identity-devops/blob/master/bin/asg-recycle.sh.

Autoscaling groups support health checks to tell AWS when an instance is healthy
and contributes to the desired count, or is unhealthy and must be replaced.
Currently, we have load balancers for the IDP servers, so AWS can do this, but
we don’t have this for other instance types, so these must be checked manually
to make sure they’re working before scaling back down.

see the [Recycling Instances Documentation](deployment/recycling-instances.md)
for more details.

### Appendix A: Administration/Troubleshooting

Secrets in s3 can be administered using the aws cli s3 functionality, and all
other configuration is managed using git.

We also have [administrative tools](tools.md) to directly interact with our AWS
instances should there be a need.

### Appendix B: Branch/AMI Configuration

```
# identity-devops-private branch
echo "export TF_VAR_bootstrap_private_git_ref=master" >> env/mycowenv.sh

# identity-devops branch
echo "export TF_VAR_bootstrap_main_git_ref=stages/mycowenv" >> env/mycowenv.sh

# Application branch.  Example only, don't actually do this.
ruby -e 'require "json"; \
j = JSON.parse(File.open("kitchen/environments/dev.json").read); \
j["default_attributes"]["login_dot_gov"]["branch_name"] = "stages/mycowenv"; puts j'

# Base AMI
echo "export TF_VAR_myfavoritecow_ami_id=ami-deadbeef" >> env/mycowenv.sh
```

On each instance, there are four main things that can be configured, the branch
for the main chef code (identity-devops), the branch for the bootstrap chef code
(identity-devops-private), the branch for the application code (identity-idp)
and the base AMI.

The chef code is all configured using environment variables that terraform will
pass into the autoscaling group's cloud-init configuration.

The application code is all configured using chef attributes, which should be
set to the desired values in the environment json file on the branch of
identity-devops that this instance is deployed against.

The base AMI is also configured using an environment variable that terraform
passes to the autoscaling configuration.
