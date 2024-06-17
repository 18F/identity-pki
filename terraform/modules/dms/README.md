## Example
```hcl
module "dms" {
  source = "../modules/dms"

  env_name     = var.env_name
  rds_password = var.rds_password
  rds_username = var.rds_username
  cert_bucket  = local.secrets_bucket

  source_db_address           = module.idp_aurora_uw2.writer_instance_endpoint
  target_db_address           = module.idp_aurora_uw2.writer_instance_endpoint
  source_db_allocated_storage = 3000
  source_db_availability_zone = module.idp_aurora_uw2.writer_instance_az
  source_db_instance_class    = var.rds_instance_class
  rds_kms_key_arn             = data.aws_kms_key.dms_alias.arn
  log_retention_days          = local.retention_days

  subnet_ids = module.network_uw2.db_subnet_ids

  vpc_security_group_ids = [
    module.network_uw2.db_security_group,
    aws_security_group.idp.id
  ]
}
```
<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.dms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_dms_certificate.dms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dms_certificate) | resource |
| [aws_dms_endpoint.aurora_source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dms_endpoint) | resource |
| [aws_dms_endpoint.aurora_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dms_endpoint) | resource |
| [aws_dms_replication_instance.dms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dms_replication_instance) | resource |
| [aws_dms_replication_subnet_group.dms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dms_replication_subnet_group) | resource |
| [aws_iam_role.dms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.dms_deny_create_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.dms_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.dms_cloudwatch_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.dms_redshift_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.dms_vpc_management](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_policy_document.dms_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.dms_deny_create_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.dms_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_s3_object.ca_certificate_file](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_object) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cert_bucket"></a> [cert\_bucket](#input\_cert\_bucket) | Bucket for ca file | `string` | n/a | yes |
| <a name="input_env_name"></a> [env\_name](#input\_env\_name) | Name of application environment | `string` | n/a | yes |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | How long to keep dms logs | `any` | n/a | yes |
| <a name="input_rds_kms_key_arn"></a> [rds\_kms\_key\_arn](#input\_rds\_kms\_key\_arn) | KMS key used to encrypt rds | `string` | n/a | yes |
| <a name="input_rds_password"></a> [rds\_password](#input\_rds\_password) | Password for rds instances | `string` | n/a | yes |
| <a name="input_rds_username"></a> [rds\_username](#input\_rds\_username) | Username for rds instances | `string` | n/a | yes |
| <a name="input_source_db_address"></a> [source\_db\_address](#input\_source\_db\_address) | Source database address | `string` | n/a | yes |
| <a name="input_source_db_allocated_storage"></a> [source\_db\_allocated\_storage](#input\_source\_db\_allocated\_storage) | Source database allocated storage | `string` | n/a | yes |
| <a name="input_source_db_availability_zone"></a> [source\_db\_availability\_zone](#input\_source\_db\_availability\_zone) | Source database availability zone | `string` | n/a | yes |
| <a name="input_source_db_instance_class"></a> [source\_db\_instance\_class](#input\_source\_db\_instance\_class) | Source database instance class | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet ids | `list(any)` | n/a | yes |
| <a name="input_target_db_address"></a> [target\_db\_address](#input\_target\_db\_address) | Source database address | `string` | n/a | yes |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | List of security group ids | `list(any)` | n/a | yes |
| <a name="input_dms_engine_version"></a> [dms\_engine\_version](#input\_dms\_engine\_version) | Engine version of the DMS replication instance. | `string` | `"3.5.1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dms_policy_arn"></a> [dms\_policy\_arn](#output\_dms\_policy\_arn) | n/a |
| <a name="output_dms_replication_instance_arn"></a> [dms\_replication\_instance\_arn](#output\_dms\_replication\_instance\_arn) | n/a |
| <a name="output_dms_role"></a> [dms\_role](#output\_dms\_role) | n/a |
| <a name="output_dms_source_endpoint_arn"></a> [dms\_source\_endpoint\_arn](#output\_dms\_source\_endpoint\_arn) | n/a |
| <a name="output_dms_target_endpoint_arn"></a> [dms\_target\_endpoint\_arn](#output\_dms\_target\_endpoint\_arn) | n/a |
<!-- END_TF_DOCS -->
