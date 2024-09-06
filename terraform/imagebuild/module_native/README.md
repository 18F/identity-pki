### Building New Pipelines

 - Add the main_native module 

### Importing Existing Pipelines

 - Destroy or disable Cloudformation Stacks and retain existing resources -> https://aws.amazon.com/premiumsupport/knowledge-center/delete-cf-stack-retain-resources/
 - Replace the main module with a main_native module at the top level 
 - Override terraform resource names with existing resource names using the input variables such as var.base_pipeline_name
 - Import existing imagebuild resources
 - Set the IP address of the EIP in the top-level variables.tf as var.image_build_nat_eip
 - Do a full Terraform run

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.5.7 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | 2.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.43.0 |
| <a name="requirement_cloudinit"></a> [cloudinit](#requirement\_cloudinit) | 2.3.2 |
| <a name="requirement_external"></a> [external](#requirement\_external) | 2.3.1 |
| <a name="requirement_github"></a> [github](#requirement\_github) | 5.25.0 |
| <a name="requirement_http"></a> [http](#requirement\_http) | 3.4.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | 2.4.0 |
| <a name="requirement_newrelic"></a> [newrelic](#requirement\_newrelic) | 3.22.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | 3.2.1 |
| <a name="requirement_random"></a> [random](#requirement\_random) | 3.5.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.43.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ami_lifecycle_use1"></a> [ami\_lifecycle\_use1](#module\_ami\_lifecycle\_use1) | ../../modules/ami_lifecycle | n/a |
| <a name="module_ami_lifecycle_usw2"></a> [ami\_lifecycle\_usw2](#module\_ami\_lifecycle\_usw2) | ../../modules/ami_lifecycle | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.codebuild_failure](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_rule.nightly_trigger](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.codebuild_failure](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.nightly_base](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.nightly_rails](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.imagebuild_base](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.imagebuild_rails](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/cloudwatch_log_group) | resource |
| [aws_codebuild_project.base_image](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/codebuild_project) | resource |
| [aws_codebuild_project.rails_image](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/codebuild_project) | resource |
| [aws_codepipeline.base_image](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/codepipeline) | resource |
| [aws_codepipeline.rails_image](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/codepipeline) | resource |
| [aws_iam_instance_profile.packer](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.cloudwatch_events](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/iam_role) | resource |
| [aws_iam_role.codebuild](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/iam_role) | resource |
| [aws_iam_role.codepipeline](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/iam_role) | resource |
| [aws_iam_role.packer](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/iam_role) | resource |
| [aws_s3_bucket.codepipeline](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.codepipeline](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.codepipeline](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.codepipeline](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.codepipeline](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/s3_bucket_versioning) | resource |
| [aws_security_group.main](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/security_group) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.cloudwatch_events](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.codebuild](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.codepipeline](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.packer](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/data-sources/region) | data source |
| [aws_s3_bucket.access_logging](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/data-sources/s3_bucket) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_name"></a> [account\_name](#input\_account\_name) | n/a | `string` | n/a | yes |
| <a name="input_env_name"></a> [env\_name](#input\_env\_name) | n/a | `string` | n/a | yes |
| <a name="input_private_subnet_id"></a> [private\_subnet\_id](#input\_private\_subnet\_id) | the subnet id that is passed to packer for image building | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | the VPC id that is passed to packer for image building | `string` | n/a | yes |
| <a name="input_ami_copy_region"></a> [ami\_copy\_region](#input\_ami\_copy\_region) | The name of a region that Packer copies AMIs to | `string` | `"us-east-1"` | no |
| <a name="input_ami_lifecycle_enabled"></a> [ami\_lifecycle\_enabled](#input\_ami\_lifecycle\_enabled) | Enable AMI lifecycle cleanup | `bool` | `false` | no |
| <a name="input_ami_regions"></a> [ami\_regions](#input\_ami\_regions) | List of region(s) where AMIs should exist. AMIs are created in us-west-2 and will be<br>copied to other regions IFF this variable has more than one region listed. | `list(string)` | <pre>[<br>  "us-west-2",<br>  "us-east-1"<br>]</pre> | no |
| <a name="input_associate_public_ip"></a> [associate\_public\_ip](#input\_associate\_public\_ip) | associate a public IP | `bool` | `"false"` | no |
| <a name="input_base_codebuild_name"></a> [base\_codebuild\_name](#input\_base\_codebuild\_name) | name of base codebuild project | `string` | `""` | no |
| <a name="input_base_pipeline_name"></a> [base\_pipeline\_name](#input\_base\_pipeline\_name) | name of base codepipeline | `string` | `""` | no |
| <a name="input_build_alarms_enable"></a> [build\_alarms\_enable](#input\_build\_alarms\_enable) | Enable build alarms | `bool` | `false` | no |
| <a name="input_codebuild_build_timeout"></a> [codebuild\_build\_timeout](#input\_codebuild\_build\_timeout) | the time codebuild allows a build to run before failing the build | `string` | `"120"` | no |
| <a name="input_codebuild_role_name"></a> [codebuild\_role\_name](#input\_codebuild\_role\_name) | name of base codebuild iam role | `string` | `""` | no |
| <a name="input_codepipeline_role_name"></a> [codepipeline\_role\_name](#input\_codepipeline\_role\_name) | name of base codepipeline iam role | `string` | `""` | no |
| <a name="input_codepipeline_s3_bucket_name"></a> [codepipeline\_s3\_bucket\_name](#input\_codepipeline\_s3\_bucket\_name) | name of bucket to store codepipeline artifacts | `string` | `""` | no |
| <a name="input_fisma_tag"></a> [fisma\_tag](#input\_fisma\_tag) | n/a | `string` | `"Q-LG"` | no |
| <a name="input_git2s3_bucket_name"></a> [git2s3\_bucket\_name](#input\_git2s3\_bucket\_name) | name of default git2s3 bucket for non\_sandbox envs | `string` | `"codesync-identitybaseimage-outputbucket-rlnx3kivn8t8"` | no |
| <a name="input_identity_base_git_ref"></a> [identity\_base\_git\_ref](#input\_identity\_base\_git\_ref) | git ref to check out | `string` | `""` | no |
| <a name="input_identity_base_image_zip_s3_path"></a> [identity\_base\_image\_zip\_s3\_path](#input\_identity\_base\_image\_zip\_s3\_path) | object to poll for source changes | `string` | `""` | no |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | `"login"` | no |
| <a name="input_nightly_build_trigger"></a> [nightly\_build\_trigger](#input\_nightly\_build\_trigger) | build AMIs nightly | `bool` | `true` | no |
| <a name="input_packer_config"></a> [packer\_config](#input\_packer\_config) | Map of key/value pairs for Packer configs consistent in all AMI types in account.<br>Main number for os\_version and ami\_filter\_name MUST be the same as var.os\_number. | `map(string)` | <pre>{<br>  "ami_filter_name": "ubuntu-pro-fips-server/images/hvm-ssd/ubuntu-focal-20.04-amd64*",<br>  "ami_owner_id": "679593333241",<br>  "berkshelf_version": "8.0.15",<br>  "chef_version": "18.4.12",<br>  "data_vol_size": "200",<br>  "delay_seconds": "60",<br>  "delete_ami_snapshots": "false",<br>  "deregister_existing_ami": "false",<br>  "encryption": "true",<br>  "inspec_version": "5.22.40",<br>  "instance_type": "c6i.2xlarge",<br>  "max_attempts": "50",<br>  "os_version": "Ubuntu 20.04",<br>  "packer_version": "1.10.2",<br>  "root_vol_size": "40",<br>  "ubuntu_major_version": "20"<br>}</pre> | no |
| <a name="input_packer_instance_profile_name"></a> [packer\_instance\_profile\_name](#input\_packer\_instance\_profile\_name) | name of instance profile | `string` | `""` | no |
| <a name="input_packer_role_name"></a> [packer\_role\_name](#input\_packer\_role\_name) | name of base packer iam role | `string` | `""` | no |
| <a name="input_rails_codebuild_name"></a> [rails\_codebuild\_name](#input\_rails\_codebuild\_name) | name of rails codebuld project | `string` | `""` | no |
| <a name="input_rails_pipeline_name"></a> [rails\_pipeline\_name](#input\_rails\_pipeline\_name) | name of rails codepipeline | `string` | `""` | no |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `"us-west-2"` | no |
| <a name="input_repo"></a> [repo](#input\_repo) | git repo to check out | `string` | `"identity-base-image"` | no |
| <a name="input_slack_events_sns_hook_name"></a> [slack\_events\_sns\_hook\_name](#input\_slack\_events\_sns\_hook\_name) | Name of SNS topic that send notifications to Slack | `string` | `"slack-events"` | no |
| <a name="input_source_build_trigger"></a> [source\_build\_trigger](#input\_source\_build\_trigger) | build AMIs when the s3 source file is updated | `bool` | `true` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->