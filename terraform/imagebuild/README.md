# `terraform/imagebuild` | AMIs (And So Can You!)

Terraform moduleset that creates the architecture for building AMIs from the `identity-base-image` repo. Detailed information about the architecture, and building AMIs, can be found within the wiki:

- https://github.com/18F/identity-devops/wiki/EC2-AMIs-via-Imagebuild-Pipeline
- https://github.com/18F/identity-devops/wiki/Baking-New-AWS-AMI-Images

# Updating/Changing Resources

As most of the individual resources within this moduleset are created in their associated CloudFormation stacks, changes/updates to those resources *must*, for the most part, be done within the CloudFormation template. The stacks themselves will update with a subsequent `terraform apply`, as long as there ARE changes to the template(s) within.

# Future/Desired Changes

A few particulars:

1. Create Slack/SNS alerts for actions/updates, i.e.:
    - CodeBuild execution successes/failures, including (truncated, if possible) the reason build(s) fail if/when they do
    - CodePipeline release successes/failures, including which part failed (if so)
    - These alerts can then be sent via SNS to Slack, with components such as the build branch, and user executing the build, specified (as/if desired) in the alerts
2. Build some form of automation for AMI PRs, i.e.:
  - Get the AMI IDs from the completed weekly builds, then Terraform/recycle hosts in a testing environment via `auto-tf` to verify that the AMIs themselves are actually viable with our application code
  - Upon successful testing, use `bin/get-images` to create a PR with the new AMI IDs
3. Get the code in `identity-base-image` to a point where the S3 trigger source -- i.e. new code merged to `main` -- is used as the default, rather than the weekly CloudWatch event rule, in all accounts
    - This is worth some discussion, of course, as this is a FULLY-automated build process. Images are usually updated on a particular schedule, rather than ad hoc; however, working with this degree of automation can help better prepare us for container-based AMI creation/deployment in the future.