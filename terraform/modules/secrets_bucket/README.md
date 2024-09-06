# Secrets Bucket

Use this module to create an s3 bucket for storing secrets.  Given a prefix,
will properly namespace the bucket by region and account id and return the full
name to the caller.

Supports enforcing kms encryption by a specific kms key.

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_secrets_bucket_config"></a> [secrets\_bucket\_config](#module\_secrets\_bucket\_config) | github.com/18F/identity-terraform//s3_config | 6cdd1037f2d1b14315cc8c59b889f4be557b9c17 |

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket.secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_logging.secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_ownership_controls.secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Bucket Name | `string` | n/a | yes |
| <a name="input_bucket_name_prefix"></a> [bucket\_name\_prefix](#input\_bucket\_name\_prefix) | Base name for the secrets bucket to create | `string` | n/a | yes |
| <a name="input_logs_bucket"></a> [logs\_bucket](#input\_logs\_bucket) | Name of the bucket to store access logs in | `string` | n/a | yes |
| <a name="input_secrets_bucket_type"></a> [secrets\_bucket\_type](#input\_secrets\_bucket\_type) | Type of secrets stored in this bucket | `string` | n/a | yes |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | Allow destroy even if bucket contains objects | `bool` | `false` | no |
| <a name="input_object_ownership"></a> [object\_ownership](#input\_object\_ownership) | Object Ownership configuration for aws\_s3\_bucket\_ownership\_controls resource.<br>Can be set to BucketOwnerPreferred, BucketOwnerEnforced, or ObjectWriter. | `string` | `"BucketOwnerPreferred"` | no |
| <a name="input_policy"></a> [policy](#input\_policy) | An additonal Bucket policy in JSON format | `string` | `""` | no |
| <a name="input_region"></a> [region](#input\_region) | Region to create the secrets bucket in | `string` | `"us-west-2"` | no |
| <a name="input_sse_algorithm"></a> [sse\_algorithm](#input\_sse\_algorithm) | S3 Server-side Encryption Algorithm | `string` | `"aws:kms"` | no |
| <a name="input_use_kms"></a> [use\_kms](#input\_use\_kms) | Whether to encrypt the bucket with KMS | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | Name of the s3 secrets bucket that was created |
<!-- END_TF_DOCS -->