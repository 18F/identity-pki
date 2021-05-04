# `terraform/imagebuild` | AMIs (And So Can You!)

## Overview

With our move to using Ubuntu Pro/FIPS-supported AMIs for the Login.gov infrastructure hosts, `terraform/imagebuild` was created to address the following issues:

1. Amazon's new Ubuntu Pro/FIPS-supported AMIs have a _Marketplace ID_ attached to them, which prevents them from being shared/copied from one AWS account to another -- thus negating the ability to use `copy-image.sh` / `share-image.sh` in this repo to copy `sandbox` AMIs to `prod`.
2. The existing infrastructure for automated AMI builds, created/maintained by CloudFormation stacks in `identity-base-image`, is hard-coded to only use/create resources in `login-sandbox`, as opposed to having a templatized format.
3. Redesigning this infrastructure will allow for _automated, weekly builds_ of Ubuntu Pro images in any desired account -- i.e. `prod` -- negating the need for the manual process to build, copy, and share those images across accounts.

<!-- MarkdownTOC -->

- [How It Works](#how-it-works)
- [Resources/Categories](#resourcescategories)
    - [vpc/network \(`login-vpc-image-build`\)](#vpcnetwork-login-vpc-image-build)
    - [codebuild \(`login-codebuild-image`\)](#codebuild-login-codebuild-image)
    - [codepipeline \(`login-codepipeline-image`\)](#codepipeline-login-codepipeline-image)
    - [CloudFormation? In MY Terraform?](#cloudformation-in-my-terraform)
- [Updating/Changing Resources](#updatingchanging-resources)
    - [Stack-Created Resources](#stack-created-resources)
    - [Specifying the `login-image-build` Branch for CodeBuild Projects](#specifying-the-login-image-build-branch-for-codebuild-projects)
    - [Updating the `code_branch` Variable via `bin/build-images`](#updating-the-code_branch-variable-via-binbuild-images)
- [Future/Desired Changes](#futuredesired-changes)

<!-- /MarkdownTOC -->

## How It Works

Each commit that is pushed to a remote in `identity-base-image` will trigger the `GitPullLambda` function in the `login-sandbox` account, which:

1. pulls down code from `identity-base-image` (defaulting to the `main` branch)
2. creates a ZIP file with said pulled-down code
3. pushes the ZIP up to the S3 bucket `login-gov-public-artifacts-us-west-2`, also located in the `login-sandbox` account

For each type of image (i.e. `Base` and `Rails`), there are two components which actually build an AMI from said ZIP file:

1. A CodeBuild project, which uses `packer` to build an AMI from an EC2 instance via the `amazon-ebs` Packer provider.
  - The project follows the `buildspec.yml` file within the `identity-base-image` codebase, i.e. the contents of the ZIP file above.
  - Assuming that the `packer build` is successful, each project will create a new AMI within the AWS account, available for use by EC2 hosts. The encryption status of this AMI is verified in the post-build stage of the CodeBuild project (as specified in the `buildspec.yml` file).

2. A CodePipeline, er, pipeline, which serves as the orchestration for its associated CodeBuild project.
  - The pipeline will provide the S3 key name for the ZIP file to CodeBuild, and then trigger a new build within the project.
  - By default, a `cron`-driven CloudWatch Event Schedule will trigger a weekly run of the pipeline.
  - If desired, these builds can also/instead be triggered by changes pushed to the artifacts bucket by the `GitPullLambda` function.

## Resources/Categories

The main code for this full pipeline setup is made up of ***three CloudFormation stacks***, which build the following categories of infrastructure:

### vpc/network (`login-vpc-image-build`)

Creates the VPC, subnets, security groups, NACLs, route tables, etc. where the image build pipeline lives and operates.

- Entirely separate IP space (`10.0.1.0/24` for public, `10.0.11.0/24` for private) with no peering to 'main' VPCs, i.e. the `172*` space that the application runs in
- S3 Endpoints and NAT Gateway created to allow CodeBuild/`packer` access to the bucket(s)/repo(s) needed to build images

<details><summary> Full Resource List </summary>

| Name                                | Type                                  |
| -----                               | -----                                 |
| CodeBuildVPCFlowLogs                | AWS::EC2::FlowLog                     |
| EIPNatGateway1                      | AWS::EC2::EIP                         |
| FlowLogsCloudWatchGroup             | AWS::Logs::LogGroup                   |
| FlowLogsRole                        | AWS::IAM::Role                        |
| FlowLogsRolePolicy                  | AWS::IAM::Policy                      |
| InternetGateway                     | AWS::EC2::InternetGateway             |
| NatGateway1                         | AWS::EC2::NatGateway                  |
| PrivateSecurityGroup                | AWS::EC2::SecurityGroup               |
| PrivateSubnet1                      | AWS::EC2::Subnet                      |
| PrivateSubnet1NaclAssociation       | AWS::EC2::SubnetNetworkAclAssociation |
| PrivateSubnet1Route                 | AWS::EC2::Route                       |
| PrivateSubnet1RouteTable            | AWS::EC2::RouteTable                  |
| PrivateSubnet1RouteTableAssociation | AWS::EC2::SubnetRouteTableAssociation |
| PrivateSubnetAcl                    | AWS::EC2::NetworkAcl                  |
| PrivateSubnetAclEntryInbound        | AWS::EC2::NetworkAclEntry             |
| PrivateSubnetAclEntryOutbound       | AWS::EC2::NetworkAclEntry             |
| PublicSecurityGroup                 | AWS::EC2::SecurityGroup               |
| PublicSubnet1                       | AWS::EC2::Subnet                      |
| PublicSubnet1NaclAssociation        | AWS::EC2::SubnetNetworkAclAssociation |
| PublicSubnet1RouteTableAssociation  | AWS::EC2::SubnetRouteTableAssociation |
| PublicSubnetAcl                     | AWS::EC2::NetworkAcl                  |
| PublicSubnetAclEntryInbound         | AWS::EC2::NetworkAclEntry             |
| PublicSubnetAclEntryOutbound        | AWS::EC2::NetworkAclEntry             |
| PublicSubnetRoute                   | AWS::EC2::Route                       |
| PublicSubnetRouteTable              | AWS::EC2::RouteTable                  |
| S3Endpoint                          | AWS::EC2::VPCEndpoint                 |
| VPC                                 | AWS::EC2::VPC                         |
| VPCGatewayAttachment                | AWS::EC2::VPCGatewayAttachment        |

</details>

### codebuild (`login-codebuild-image`)

Creates `BuildProject`, `OutputBucket`, and all necessary Roles and Policies for the `ImageBaseRole` and `ImageRailsRole` CodeBuild projects.
- The projects run within the separate VPC space created via `login-vpc-image-build`
- If desired, one can configure the source branch of `identity-base-image` via the `SourceFileName` parameter, and then update the CloudFormation stack accordingly.

<details><summary> resource list (example: `CodeBuild-ImageRailsRole`) </summary>

| Name                            | Type                      |
| -----                           | -----                     |
| BuildProject                    | AWS::CodeBuild::Project   |
| CodeBuildCloudWatchEventsPolicy | AWS::IAM::Policy          |
| CodeBuildIAMPolicy              | AWS::IAM::Policy          |
| CodeBuildLogPolicy              | AWS::IAM::Policy          |
| CodeBuildOutputPolicy           | AWS::IAM::Policy          |
| CodeBuildPackerPolicy           | AWS::IAM::Policy          |
| CodeBuildPackerProfile          | AWS::IAM::InstanceProfile |
| CodeBuildPackerRole             | AWS::IAM::Role            |
| CodeBuildPackerS3Policy         | AWS::IAM::Policy          |
| CodeBuildParameterPolicy        | AWS::IAM::Policy          |
| CodeBuildPipelinePolicy         | AWS::IAM::Policy          |
| CodeBuildRole                   | AWS::IAM::Role            |
| CodeBuildSecretsCommonPolicy    | AWS::IAM::Policy          |
| CodeBuildSourcePolicy           | AWS::IAM::Policy          |
| CodeBuildVpcPolicy              | AWS::IAM::Policy          |
| OutputBucket                    | AWS::S3::Bucket           |

</details>

### codepipeline (`login-codepipeline-image`)

Creates `CodePipeline` + associated roles/policies, along with the `ArtifactBucket` where artifacts from both CodeBuild and CodePipeline executions are uploaded.
- The `TriggerSource` parameter determines what specific operation will cause the CodePipeline to execute (outside of a manual request). It can be set to _S3_, _CloudWatch_, or the default of _Both_. This value has been set to _CloudWatch_ in `prod` (as well as in `alpha` and `tooling` during testing.)

<details><summary> resource list (example: `CodePipeline-ImageRailsRole`) </summary>

| Name                         | Type                        |
| -----                        | -----                       |
| ArtifactBucket               | AWS::S3::Bucket             |
| CloudWatchPipelineRole       | AWS::IAM::Role              |
| CloudWatchPipelineRolePolicy | AWS::IAM::Policy            |
| CloudWatchPipelineTrigger    | AWS::Events::Rule           |
| CodePipeline                 | AWS::CodePipeline::Pipeline |
| CodePipelineRole             | AWS::IAM::Role              |
| CodePipelineRolePolicy       | AWS::IAM::Policy            |

</details>

### CloudFormation? In MY Terraform?

It's more likely than you think.

Unlike the rest of our Terraform modulesets, the majority of the resources created here are built and maintained within a set of CloudFormation templates. Reasons for this include:

- The original imagebuild pipelines within `login-sandbox` were created using CloudFormation, with the templates originally existing within the `identity-base-image` repo as well
- There isn't one canonical be-all-end-all tool that can easily convert a CloudFormation template into a Terraform `.tf` file, which would thus require building the Terraform template manually + from scratch
- Moving the resource control scope from CloudFormation to Terraform -- *without* allowing the former to destroy the resources it maintained -- is a particularly onerous task, and impossible to do with certain resources

Thus, while CloudFormation templates are, in general, far more verbose than Terraform ones are (at least within our infrastructure), it made more sense to continue maintaining these resources within the existing templates/stacks, and to use these templates for building the imagebuild infrastructure in newer/additional accounts, including `login-prod`.

## Updating/Changing Resources

### Stack-Created Resources

As most of the individual resources within this moduleset are created in their associated CloudFormation stacks, changes/updates to those resources *must*, for the most part, be done within the CloudFormation template. The stacks themselves will update with a subsequent `terraform apply`, as long as there ARE changes to the template(s) within.

### Specifying the `login-image-build` Branch for CodeBuild Projects

One update made to the CloudFormation templates was to use an SSM parameter, `ImageCreationSourceFile`, to specify which branch of the `login-image-build` CodeBuild should use when creating AMIs with `packer`. The value for this parameter is specified in Terraform, using the variable `code_branch`, and defaults to `main` in all accounts it is used within.

Previously, this was a manually-specified CloudFormation parameter, which thus required resource changes/recreations if it was updated. However, the three main types of CFN stacks have so many interwoven dependencies that updating just *one* of them is impossible -- it would, in many cases, require an entire recreation of the associated stack, rather than just a parameter update. An SSM parameter, on the other hand, is a [dynamic reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/dynamic-references.html), whose value is retrieved *only* when required by a Stack/the resource(s) that use it.

### Updating the `code_branch` Variable via `bin/build-images`

If one is working on a development branch in `identity-base-image`, and wants to test that code within the imagebuild moduleset here, it requires:

1. updating the `ImageCreationSourceFile` SSM parameter
2. running `terraform apply` against `imagebuild/<ACCOUNT>` to update the parameter
3. updating either/both CodeBuild stack(s) to read the new parameter value and update the associated env var in the CodeBuild project(s)
4. triggering a new release on either/both CodePipeline stack(s) so that the ZIP file containing the `identity-base-image` code is properly loaded into the CodeBuild project(s) when executing

Since the process requires *several* manual steps, the easier way to do this is to simply use `bin/build-images -a <ACCOUNT>`, which will perform any/all of the steps above, depending upon the flag(s) used:

```
  -b BRANCH : Update the identity-base-image branch
              used for builds to $BRANCH, via
              tf-deploy and aws cloudformation
  -t TYPE   : Only update the stacks/build project/
              pipeline for $TYPE AMIs (base/rails)
```
Since the full execution of the CodeBuild projects takes a significant amount of time (~45-55 minutes), the script will end by triggering new releases in the CodePipeline(s) specified (both, by default), and then exit; the full progress of each execution can then be viewed in the AWS Console, within either CodeBuild or CloudWatch logs.

## Future/Desired Changes

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