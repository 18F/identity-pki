# config_access_key_rotation
This module monitors the IAM User's Access keys. It performs the following:

- Inactivate the access key if it has not been rotated in the last 90days or if it's age is beyond 100days 
- Send a notification via email using SES, when the password age is between 80 and 90 days
- This implementation does not delete the access keys for user, thus for access keys with age older than 90days are all made inactive. However, with a slight modification to lambda, we should be able to delete the access keys that are older than 100 days(future implementation).

## Architecture Diagram: IAM Access Key Rotation Diagram

![Iam Access key Rotation](./diagrams/access_keys_rotation.png)

## Workflow
- Lambda is triggered by the Cloudwatch event rule at a specific time of the day
- Lambda once triggered, lists the IAM users in the Account and checks the access keys associated with the user. Evaluates the active access key/s to see if the user has to be notified about the rotation or takes no action if the access key/s are still new. 
- Lambda sends an email to the user once the key is made inactive.
- Lambda when inactivating the users' access key, runs the api "iam:UpdateAccessKey". For this specific action it will use a temporary role with ability to update access key just for that specific user. While assuming the temporary role, lambda should only have permissions that is overlap of the temporary role and the policy it uses during assuming this role.
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
| <a name="module_config_access_key_rotation_alerts"></a> [config\_access\_key\_rotation\_alerts](#module\_config\_access\_key\_rotation\_alerts) | github.com/18F/identity-terraform//lambda_alerts | 0cb56606de47507e5748ab55bfa51fa72424313f |
| <a name="module_config_access_key_rotation_code"></a> [config\_access\_key\_rotation\_code](#module\_config\_access\_key\_rotation\_code) | github.com/18F/identity-terraform//null_archive | 6cdd1037f2d1b14315cc8c59b889f4be557b9c17 |
| <a name="module_lambda_insights"></a> [lambda\_insights](#module\_lambda\_insights) | github.com/18F/identity-terraform//lambda_insights | 0cb56606de47507e5748ab55bfa51fa72424313f |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.trigger_schedule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.trigger_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_role.assumeRole_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.config_access_key_rotation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.assumeRole_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.config_access_key_rotation_iam_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.config_access_key_rotation_lambda_insights](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.config_access_key_rotation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.allow_cloudwatch_to_invoke_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_iam_policy_document.assume_lambda_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.identity_policy_allowing_lambda_assumeRole](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_iam_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.trust_policy_allowing_lambda_assumeRole](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_sns_topic.alarm_targets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/sns_topic) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alarm_sns_topics"></a> [alarm\_sns\_topics](#input\_alarm\_sns\_topics) | List of SNS topics to alert to when alarms trigger | `set(string)` | n/a | yes |
| <a name="input_cloudwatch_retention_days"></a> [cloudwatch\_retention\_days](#input\_cloudwatch\_retention\_days) | Number of days to retain CloudWatch Logs for the Lambda function.<br>Defaults to 0 (never expire). | `number` | `0` | no |
| <a name="input_config_access_key_rotation_code"></a> [config\_access\_key\_rotation\_code](#input\_config\_access\_key\_rotation\_code) | Path of the compressed lambda source code. Relative to module path. | `string` | `"config-access-key-rotation.zip"` | no |
| <a name="input_config_access_key_rotation_name"></a> [config\_access\_key\_rotation\_name](#input\_config\_access\_key\_rotation\_name) | Name of the Config access key rotation, used to name other resources | `string` | `"cfg-access-key-rotation"` | no |
| <a name="input_lambda_runtime"></a> [lambda\_runtime](#input\_lambda\_runtime) | Runtime for Lambda | `string` | `"python3.9"` | no |
| <a name="input_lambda_timeout"></a> [lambda\_timeout](#input\_lambda\_timeout) | Timeout Value for Lambda | `number` | `"900"` | no |
| <a name="input_schedule"></a> [schedule](#input\_schedule) | Cron expression for cloudwatch event rule schedule | `string` | `"cron(0 22 * * ? *)"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
