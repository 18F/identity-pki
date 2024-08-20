### Setting Up New Accounts \ VPCs

 - Add the main_vpc module 
 - Obtain an unassociated EIP from the available pool
 - Import that EIP into module.main_vpc.aws_eip.main
 - Set the IP address of the EIP in the top-level variables.tf as var.image_build_nat_eip
 - Do a full Terraform run

```
EIPS=(`aws ec2 describe-addresses --output text --query 'Addresses[?AssociationId==null].PublicIp'`)
tf-deploy imagebuild/[insert env name here] import module.main_native.aws_eip.main $EIPS[1]
[add EIP IP in variables.tf]
tf-deploy imagebuild/[insert account name here] apply

```

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

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.flow](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/cloudwatch_log_group) | resource |
| [aws_flow_log.main](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/flow_log) | resource |
| [aws_iam_role.flow](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.flow_policy](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/iam_role_policy) | resource |
| [aws_internet_gateway.main](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.main](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/nat_gateway) | resource |
| [aws_route.private_default_ipv4](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/route) | resource |
| [aws_route.public_default_ipv4](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/route) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/route_table) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/route_table_association) | resource |
| [aws_security_group.endpoint](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/security_group) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/subnet) | resource |
| [aws_vpc.main](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/vpc) | resource |
| [aws_vpc_endpoint.ec2](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_security_group_ingress_rule.endpoint_communications](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_eip.main](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/data-sources/eip) | data source |
| [aws_iam_policy_document.flow_logs_assumable](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.flow_policy](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/5.43.0/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_name"></a> [account\_name](#input\_account\_name) | The login.gov alias associated with the account. Primarily used for identifying resources. | `string` | n/a | yes |
| <a name="input_image_build_nat_eip"></a> [image\_build\_nat\_eip](#input\_image\_build\_nat\_eip) | Elastic IP address for the NAT gateway.<br>Must already be allocated via other means. | `string` | n/a | yes |
| <a name="input_assign_generated_ipv6_cidr_block"></a> [assign\_generated\_ipv6\_cidr\_block](#input\_assign\_generated\_ipv6\_cidr\_block) | enable ipv6 | `bool` | `"false"` | no |
| <a name="input_cloudwatch_retention_days"></a> [cloudwatch\_retention\_days](#input\_cloudwatch\_retention\_days) | Cloudwatch Retention Policy | `number` | `90` | no |
| <a name="input_fisma_tag"></a> [fisma\_tag](#input\_fisma\_tag) | n/a | `string` | `"Q-LG"` | no |
| <a name="input_image_build_private_cidr"></a> [image\_build\_private\_cidr](#input\_image\_build\_private\_cidr) | CIDR block for the public subnet 1 | `string` | `"10.0.11.0/24"` | no |
| <a name="input_image_build_public_cidr"></a> [image\_build\_public\_cidr](#input\_image\_build\_public\_cidr) | CIDR block for the public subnet 1 | `string` | `"10.0.1.0/24"` | no |
| <a name="input_image_build_vpc_cidr"></a> [image\_build\_vpc\_cidr](#input\_image\_build\_vpc\_cidr) | CIDR block for the VPC | `string` | `"10.0.0.0/19"` | no |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | `"login"` | no |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `"us-west-2"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_private_subnet_id"></a> [private\_subnet\_id](#output\_private\_subnet\_id) | n/a |
| <a name="output_public_subnet_id"></a> [public\_subnet\_id](#output\_public\_subnet\_id) | n/a |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | n/a |
<!-- END_TF_DOCS -->