# terraform/imagebuild: security/compliance-approved pipeline for building Ubuntu Pro/FIPS AMIs

# Overview
With our move to using Ubuntu Pro/FIPS-supported AMIs for the Login.gov infrastructure hosts, `terraform/imagebuild` was created to address the following issues:

1. Amazon's new Ubuntu Pro/FIPS-supported AMIs have a _Marketplace ID_ attached to them, which prevents them from being shared/copied from one AWS account to another -- thus negating the ability to use `copy-image.sh` / `share-image.sh` in this repo, in order to copy `sandbox` AMIs to `prod`.
2. The existing infrastructure for automated AMI builds, created/maintained by CloudFormation stacks in `identity-base-image`, is hard-coded to only use/create resources in `login-sandbox`, as opposed to having a templatized format.
3. Redesigning this infrastructure will allow for _automated, weekly builds_ of Ubuntu Pro images in any desired account -- i.e. `prod` -- negating the need for the manual process to build, copy, and share those images across accounts.

# How It Works
Each commit that is pushed to a remote branch in `identity-base-image` will trigger the `GitPullLambda` function in the `login-sandbox` account, which:
1. pulls down the full repo code at that commit SHA
2. creates a ZIP file with said pulled-down code
3. pushes the ZIP up to the S3 bucket `login-gov-public-artifacts-us-west-2`, also located in the `login-sandbox` account

Originally/by default, each new ZIP file upload (to said specific remote branch) triggers a CodeBuild project (`Base`/`Rails`) via an associated CodePipeline, which:
1. pulls down the ZIP file from the artifact bucket and extracts its contents
2. following the `buildspec.yml`, runs `packer` to build an AMI from an EC2 instance (using the `amazon-ebs` Packer provider) -- essentially what is executed when one runs `create-image.sh` in the `identity-base-image` repo.
Assuming that the `packer build` is successful, each project will create a new AMI within the AWS account, available for use by EC2 hosts.

In addition to the S3 push/polling, a `cron`-driven CloudWatch Event Schedule will trigger a weekly run of the CodePipeline project. Given the two possible sources that initiate a CodePipeline execution -- as well as the fact that new images for, say, `prod` should probably _not_ be created with every new commit pushed to the `main` branch of `identity-base-image` -- the source trigger can be configured, individually, for each account AND each pipeline.

# CloudFormation stacks
The infrastructure for this full pipeline setup is made up of 3 CloudFormation stacks:

## vpc/network (`login-vpc-image-build`)
Creates the VPC, subnets, security groups, NACLs, route tables, etc. where the image build pipeline lives and operates.
- Entirely separate IP space (`10.0.1.0/24` for public, `10.0.11.0/24` for private) with no peering to 'main' VPCs, i.e. the `172*` space that the application runs in
- S3 Endpoints and NAT Gateway created to allow CodeBuild/`packer` access to the bucket(s)/repo(s) needed to build images

<details><summary> Full Resource List </summary>

| Name                                | Type                                  |
| -----                               | -----                                 |
| EIPNatGateway1                      | AWS::EC2::EIP                         |
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

## codebuild (`login-codebuild-image`)
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
| CodeBuildSourcePolicy           | AWS::IAM::Policy          |
| CodeBuildVpcPolicy              | AWS::IAM::Policy          |
| OutputBucket                    | AWS::S3::Bucket           |

</details>

## codepipeline (`login-codepipeline-image`)
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

