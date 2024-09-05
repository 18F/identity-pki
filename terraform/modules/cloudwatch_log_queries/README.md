Creates base Cloudwatch Logs Insights queries for environments

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
| [aws_cloudwatch_query_definition.db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_query_definition) | resource |
| [aws_cloudwatch_query_definition.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_query_definition) | resource |
| [aws_cloudwatch_query_definition.obproxy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_query_definition) | resource |
| [aws_cloudwatch_query_definition.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_query_definition) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_db_types"></a> [db\_types](#input\_db\_types) | Database types | `map` | n/a | yes |
| <a name="input_env_name"></a> [env\_name](#input\_env\_name) | Environment name, e.g. 'dev', 'staging', 'prod' | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `"us-west-2"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->