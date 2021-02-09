# Auto-Terraform

This directory contains the code that sets up the global stuff that all pipelines need
in `module`, and then calls `module-pipeline` with arguments for each tf dir you want
to build.

Codebuild notices changes in the branch you specify and thus will deploy that tf dir to whatever
env in the account you have specified.  You can go look at the pipelines in the tooling account
to see how they are doing.

The terraform stuff runs using a [terraform bundle](https://github.com/hashicorp/terraform/tree/master/tools/terraform-bundle)
so that we are using tooling that we have specified, and not something dynamically downloaded.
You can update this bundle by editing `bin/terraform-bundle` to update versions of plugins and tf
and then running `aws-vault exec tooling-admin -- bin/terraform-bundle.sh`,
which will upload the new bundle to the tooling auto-tf bucket.  The terraform stuff is only allowed
to access github IP addresses externally, in an attempt to make this system really locked down,
since it will be the lever that can move anything in the login.gov system.

## Issues

* It was a huge PITA to figure out how to grant access to the terraform role from
  the auto-tf role.
* Some endpoints cannot be turned into VPC endpoints.  Grr.  So we need to set up
  a Network Firewall for them.
    * iam.amazonaws.com
    * sts.us-east-1.amazonaws.com
    * access-analyzer.us-west-2.amazonaws.com
* If the build fails because it takes too long or you stop the build,
  it just kills everything immediately rather than gracefully letting terraform
  unlock itself and so on.
