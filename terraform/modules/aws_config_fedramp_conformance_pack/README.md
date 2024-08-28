<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.5.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >=5.43.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >=5.43.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_config_conformance_pack.fedramp_moderate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_conformance_pack) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloudwatch_log_group_min_retention"></a> [cloudwatch\_log\_group\_min\_retention](#input\_cloudwatch\_log\_group\_min\_retention) | Defines the minimum cloudwatch log group retention period AWS Config checks for | `number` | `30` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
