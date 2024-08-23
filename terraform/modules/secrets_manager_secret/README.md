Creates a Secrets Manager secret and adds an initial value.  The secret value will be stored in the terraform state file, so for non-sandbox environments, secrets must be manually updated.

NOTE: Once a replica is set, the replica cannot be removed without destroying the secret.

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
| [aws_secretsmanager_secret.secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_random_password.password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_random_password) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_exclude_characters"></a> [exclude\_characters](#input\_exclude\_characters) | String of the characters to exclude from the password. | `string` | `""` | no |
| <a name="input_exclude_lowercase"></a> [exclude\_lowercase](#input\_exclude\_lowercase) | Whether to exclude lowercase letters from the password. | `bool` | `false` | no |
| <a name="input_exclude_numbers"></a> [exclude\_numbers](#input\_exclude\_numbers) | Whether to exclude numbers from the password. | `bool` | `false` | no |
| <a name="input_exclude_punctuation"></a> [exclude\_punctuation](#input\_exclude\_punctuation) | Whether to exclude the following punctuation characters from the password: ! " # $ % & ' ( ) * + , - . / : ; < = > ? @ [ \ ] ^ \_ ` { | } ~ .<br>` | `bool` | `false` | no |
| <a name="input_exclude_uppercase"></a> [exclude\_uppercase](#input\_exclude\_uppercase) | Whether to exclude uppercase letters from the password. | `bool` | `false` | no |
| <a name="input_include_space"></a> [include\_space](#input\_include\_space) | Whether to include the space character. | `bool` | `true` | no |
| <a name="input_password_length"></a> [password\_length](#input\_password\_length) | Length of the password. | `number` | `32` | no |
| <a name="input_recovery_window_in_days"></a> [recovery\_window\_in\_days](#input\_recovery\_window\_in\_days) | number of days until the secret is no longer recoverable. Values include 0, 7-30 days | `number` | `7` | no |
| <a name="input_replica_key_id"></a> [replica\_key\_id](#input\_replica\_key\_id) | Secret | `string` | `""` | no |
| <a name="input_replica_regions"></a> [replica\_regions](#input\_replica\_regions) | Regions for secret replication | `list(any)` | `[]` | no |
| <a name="input_require_each_included_type"></a> [require\_each\_included\_type](#input\_require\_each\_included\_type) | Whether to include at least one upper and lowercase letter, one number, and one punctuation. | `bool` | `false` | no |
| <a name="input_secret_name"></a> [secret\_name](#input\_secret\_name) | Name of the secret | `string` | n/a | yes |
| <a name="input_secret_string"></a> [secret\_string](#input\_secret\_string) | Secret | `string` | `"generateRandomPassword"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_secret_id"></a> [secret\_id](#output\_secret\_id) | n/a |
<!-- END_TF_DOCS -->