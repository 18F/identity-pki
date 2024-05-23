# incoming_ses - Inbound email delivery to a S3 bucket

This terraform module contains inbound SES email configuration used for
email reception.   It is not suitable for handling sensitive
information.

If using kms:sse encryption for the destination S3 bucket remember
to give AWS SES access to the KMS key used.  See
 https://docs.aws.amazon.com/kms/latest/developerguide/services-ses.html#services-ses-permissions
 
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
| <a name="module_receive_usps_status_updates"></a> [receive\_usps\_status\_updates](#module\_receive\_usps\_status\_updates) | ../receive_usps_status_updates/ | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ses_receipt_filter.filter-block](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_receipt_filter) | resource |
| [aws_ses_receipt_rule.admin-at](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_receipt_rule) | resource |
| [aws_ses_receipt_rule.bounce-unknown](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_receipt_rule) | resource |
| [aws_ses_receipt_rule.drop-no-reply](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_receipt_rule) | resource |
| [aws_ses_receipt_rule.email_users](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_receipt_rule) | resource |
| [aws_sns_topic.admin-at](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_domain"></a> [domain](#input\_domain) | DNS domain to use as the root domain, e.g. 'login.gov' | `string` | n/a | yes |
| <a name="input_email_bucket"></a> [email\_bucket](#input\_email\_bucket) | Bucket used to store inbound SES mail | `string` | n/a | yes |
| <a name="input_email_bucket_prefix"></a> [email\_bucket\_prefix](#input\_email\_bucket\_prefix) | Prefix in the bucket to upload email under | `string` | `"inbound/"` | no |
| <a name="input_email_users"></a> [email\_users](#input\_email\_users) | List of additional users (besides admin) to accept - user@domain will be allowed and delivers to {var.email\_bucket\_prefix}user/ | `list(string)` | `[]` | no |
| <a name="input_rule_set_name"></a> [rule\_set\_name](#input\_rule\_set\_name) | n/a | `string` | `"default-rule-set"` | no |
| <a name="input_sandbox_features_enabled"></a> [sandbox\_features\_enabled](#input\_sandbox\_features\_enabled) | Generates resources and features that should only be used in sandbox accounts | `bool` | `false` | no |
| <a name="input_usps_envs"></a> [usps\_envs](#input\_usps\_envs) | n/a | `list(string)` | `[]` | no |
| <a name="input_usps_features_enabled"></a> [usps\_features\_enabled](#input\_usps\_features\_enabled) | Generates resources necessary for usps status updates via email. | `bool` | `false` | no |
| <a name="input_usps_ip_addresses"></a> [usps\_ip\_addresses](#input\_usps\_ip\_addresses) | List of permitted USPS IP address blocks to allow receiving email messages | `list(string)` | <pre>[<br>  "56.0.84.0/24",<br>  "56.0.86.0/24",<br>  "56.0.103.0/24",<br>  "56.0.143.0/24",<br>  "56.0.146.0/24"<br>]</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
