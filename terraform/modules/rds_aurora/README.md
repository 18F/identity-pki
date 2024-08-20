# `rds_aurora`

This Terraform module is used to create an AWS Aurora DB cluster, with configuration options for the cluster available in variable/conditional form. Its primary function is to create a replica cluster pointing to a source RDS database, along with as many instances as desired and any/all associated resources.

Additionally, once the cluster has been fully created and configured to be a standalone cluster -- thereby allowing individual instances for writing and reading (with as many reader instances as desired) -- Auto Scaling can be added and configured by setting `var.enable_autoscaling` to *true*.

### Creating a Replica Cluster from an Existing RDS Database

This module can be used as a means for migrating from an existing RDS database to a new Aurora DB cluster. If doing so, the `var.rds_db_arn` must be declared with the ARN of the source RDS database (used to configure the `replication_source_identifier` attribute.) Please note:

1. By configuration changes alone, Terraform is ***not*** able to promote a read-replica Aurora DB cluster to a standalone one. As a result, using this module for the process will require a combination of code commits (following GitOps principles) *and* manual API operations for the full process.
2. If `var.rds_db_arn` is not declared -- thus indicating the desire to create a standalone Aurora DB cluster, without an existing database to replicate -- then `var.rds_username` and `var.rds_password` ***must*** be declared instead.
3. If `var.rds_db_arn` *is* declared, the module will set both `var.rds_username` and `var.rds_password` to be empty strings (`""`), as a DB cannot be created with a manually-supplied username/password combination ***and*** a source DB ARN.

## Example

```terraform
module "db_aurora" {
  source = "terraform/modules/rds_aurora"

  name_prefix               = "identity"
  region                    = "us-west-2"
  env_name                  = var.env_name
  db_identifier             = "primary"
  rds_db_arn                = aws_db_instance.primary.arn # externally-created resource
  primary_cluster_instances = 1
  key_admin_role_name       = "KMSAdministrator"
  db_instance_class         = var.rds_instance_class
  db_engine                 = var.rds_engine
  db_engine_version         = var.rds_engine_version_uw2
  db_port                   = var.rds_db_port
  retention_period          = var.rds_backup_retention_period
  backup_window             = var.rds_backup_window
  maintenance_window        = var.rds_maintenance_window
  auto_minor_upgrades       = false
  major_upgrades            = true
  apg_cluster_pgroup_params = flatten([
    local.apg_cluster_pgroup_params,
    local.apg_param_max_standby_streaming_delay
  ])
  apg_db_pgroup_params = local.apg_db_pgroup_params
  db_subnet_ids        = aws_db_subnet_group.persistent_storage # externally-created resource
  db_security_group    = aws_security_group.db.id
  storage_encrypted    = true
  db_kms_key_id        = data.aws_kms_key.rds_alias.arn
  cw_logs_exports      = ["postgresql"]
  pi_enabled           = true
  monitoring_interval  = var.rds_enhanced_monitoring_interval
  monitoring_role      = join(":", [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}",
    "role/${var.rds_monitoring_role_name}"
  ])
  
  internal_zone_id = aws_route53_zone.internal.zone_id # externally-created resource
  route53_ttl      = 300  
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
| [aws_appautoscaling_policy.db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_target.db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | resource |
| [aws_cloudwatch_log_group.aurora](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_role.rds_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.rds_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_rds_cluster.aurora](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster) | resource |
| [aws_rds_cluster_instance.aurora](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster_instance) | resource |
| [aws_rds_global_cluster.aurora](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_global_cluster) | resource |
| [aws_availability_zones.region](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_kms_key.rds_alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_apg_cluster_pgroup"></a> [apg\_cluster\_pgroup](#input\_apg\_cluster\_pgroup) | (REQUIRED) Name of an existing parameter group to use for the DB cluster. | `string` | n/a | yes |
| <a name="input_apg_db_pgroup"></a> [apg\_db\_pgroup](#input\_apg\_db\_pgroup) | (REQUIRED) Name of an existing parameter group to use for the DB cluster instance(s). | `string` | n/a | yes |
| <a name="input_db_identifier"></a> [db\_identifier](#input\_db\_identifier) | Unique identifier for the database (e.g. default/primary/etc.) | `string` | n/a | yes |
| <a name="input_db_security_group"></a> [db\_security\_group](#input\_db\_security\_group) | (REQUIRED) VPC Security Group ID used by the AuroraDB cluster | `string` | n/a | yes |
| <a name="input_db_subnet_group"></a> [db\_subnet\_group](#input\_db\_subnet\_group) | (REQUIRED) Name of DB subnet group used by the AuroraDB cluster | `string` | n/a | yes |
| <a name="input_env_name"></a> [env\_name](#input\_env\_name) | Environment name | `string` | n/a | yes |
| <a name="input_key_admin_role_name"></a> [key\_admin\_role\_name](#input\_key\_admin\_role\_name) | (REQUIRED) Name of an external IAM role to be granted permissions<br>to interact with the KMS key used for encrypting the database | `string` | n/a | yes |
| <a name="input_rds_password"></a> [rds\_password](#input\_rds\_password) | Password for the RDS master user account | `string` | n/a | yes |
| <a name="input_rds_username"></a> [rds\_username](#input\_rds\_username) | Username for the RDS master user account | `string` | n/a | yes |
| <a name="input_auto_minor_upgrades"></a> [auto\_minor\_upgrades](#input\_auto\_minor\_upgrades) | Whether or not to perform minor engine upgrades automatically during the<br>specified in the maintenance window. Defaults to false. | `bool` | `false` | no |
| <a name="input_autoscaling_metric_name"></a> [autoscaling\_metric\_name](#input\_autoscaling\_metric\_name) | Name of the predefined metric used by the Auto Scaling policy<br>(if enabling Auto Scaling for the Aurora cluster) | `string` | `""` | no |
| <a name="input_autoscaling_metric_value"></a> [autoscaling\_metric\_value](#input\_autoscaling\_metric\_value) | Desired target value of Auto Scaling policy's predefined metric<br>(if enabling Auto Scaling for the Aurora cluster) | `number` | `40` | no |
| <a name="input_backup_window"></a> [backup\_window](#input\_backup\_window) | Daily time range (in UTC) for automated backups | `string` | `"08:00-08:34"` | no |
| <a name="input_cloudwatch_retention_days"></a> [cloudwatch\_retention\_days](#input\_cloudwatch\_retention\_days) | Number of days to retain CloudWatch Logs for groups defined in var.cw\_logs\_exports<br>Defaults to 0 (never expire). | `number` | `0` | no |
| <a name="input_copy_tags_to_snapshot"></a> [copy\_tags\_to\_snapshot](#input\_copy\_tags\_to\_snapshot) | Enables auto copying database tags to snapshots | `bool` | `true` | no |
| <a name="input_create_global_db"></a> [create\_global\_db](#input\_create\_global\_db) | Whether or not to enable creating an Aurora Global cluster AFTER the creation<br>of the aws\_rds\_cluster.aurora regional Aurora cluster. Must be set to 'false'<br>if this module instance is creating a secondary regional Aurora cluster<br>in an existing Global cluster. | `bool` | `false` | no |
| <a name="input_cw_logs_exports"></a> [cw\_logs\_exports](#input\_cw\_logs\_exports) | List of log types to export to CloudWatch. Will use ["general"] if not specified,<br>or ["postgresql"] if var.db\_engine is "aurora-postgresql". | `list(string)` | `[]` | no |
| <a name="input_db_engine"></a> [db\_engine](#input\_db\_engine) | AuroraDB engine name (aurora / aurora-mysql / aurora-postgresql) | `string` | `"aurora-postgresql"` | no |
| <a name="input_db_engine_mode"></a> [db\_engine\_mode](#input\_db\_engine\_mode) | Engine mode for the AuroraDB cluster. Must be one of:<br>"global", "multimaster", "parallelquery", "provisioned", "serverless" | `string` | `"provisioned"` | no |
| <a name="input_db_engine_version"></a> [db\_engine\_version](#input\_db\_engine\_version) | Version number (e.g. ##.#) of db\_engine to use | `string` | `"13.9"` | no |
| <a name="input_db_instance_class"></a> [db\_instance\_class](#input\_db\_instance\_class) | Instance class to use in AuroraDB cluster | `string` | `"db.r6g.large"` | no |
| <a name="input_db_kms_key_id"></a> [db\_kms\_key\_id](#input\_db\_kms\_key\_id) | (OPTIONAL) ID of an already-existing KMS Key used to encrypt the database;<br>will create the aws\_kms\_key.db / aws\_kms\_alias.db resources<br>and use those for encryption if left blank | `string` | `""` | no |
| <a name="input_db_name_override"></a> [db\_name\_override](#input\_db\_name\_override) | Manually-specified name for the Aurora cluster. Will override the<br>default pattern of env\_name-db\_identifier unless left blank. | `string` | `""` | no |
| <a name="input_db_port"></a> [db\_port](#input\_db\_port) | Database port number | `number` | `5432` | no |
| <a name="input_db_publicly_accessible"></a> [db\_publicly\_accessible](#input\_db\_publicly\_accessible) | Bool to control if instance is publicly accessible | `bool` | `false` | no |
| <a name="input_dr_restore_to_time"></a> [dr\_restore\_to\_time](#input\_dr\_restore\_to\_time) | Timestamp for point-in-time recovery (2023-04-21T12:00:00Z) | `string` | `""` | no |
| <a name="input_dr_restore_type"></a> [dr\_restore\_type](#input\_dr\_restore\_type) | n/a | `string` | `""` | no |
| <a name="input_dr_snapshot_identifier"></a> [dr\_snapshot\_identifier](#input\_dr\_snapshot\_identifier) | Identifier of the database snapshot for snapshot recovery | `string` | `""` | no |
| <a name="input_dr_source_cluster_identifier"></a> [dr\_source\_cluster\_identifier](#input\_dr\_source\_cluster\_identifier) | Identifier (name) of the source database for point-in-time recovery | `string` | `""` | no |
| <a name="input_enable_autoscaling"></a> [enable\_autoscaling](#input\_enable\_autoscaling) | Whether or not to enable Auto Scaling of read replica instances | `bool` | `false` | no |
| <a name="input_global_db_id"></a> [global\_db\_id](#input\_global\_db\_id) | Identifier for an Aurora Global cluster. MUST be specified if this module instance<br>is creating a secondary regional Aurora cluster in an existing Global cluster<br>OR if creating an Aurora Global cluster specifically within this module. | `string` | `""` | no |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | Weekly time range (in UTC) for scheduled/system maintenance | `string` | `"Sun:08:34-Sun:09:08"` | no |
| <a name="input_major_upgrades"></a> [major\_upgrades](#input\_major\_upgrades) | Whether or not to allow performing major version upgrades when<br>changing engine versions. Defaults to true. | `bool` | `true` | no |
| <a name="input_max_cluster_instances"></a> [max\_cluster\_instances](#input\_max\_cluster\_instances) | Maximum number of read replica instances to scale up to<br>(if enabling Auto Scaling for the Aurora cluster) | `number` | `5` | no |
| <a name="input_monitoring_interval"></a> [monitoring\_interval](#input\_monitoring\_interval) | Time (in seconds) to wait before each metric sample collection.<br>Disabled if set to 0. | `number` | `60` | no |
| <a name="input_monitoring_role"></a> [monitoring\_role](#input\_monitoring\_role) | (OPTIONAL) Name of an existing IAM role with the AmazonRDSEnhancedMonitoringRole<br>service role policy attached. If left blank, will create the rds\_monitoring IAM role<br>(which has said permission) within the module. | `string` | `""` | no |
| <a name="input_pi_enabled"></a> [pi\_enabled](#input\_pi\_enabled) | Whether or not to enable Performance Insights on the Aurora cluster | `bool` | `true` | no |
| <a name="input_primary_cluster_instances"></a> [primary\_cluster\_instances](#input\_primary\_cluster\_instances) | Number of instances to create for the primary AuroraDB cluster. MUST be Set to 1<br>if creating cluster as a read replica, then should be set to 2+ thereafter. | `number` | `1` | no |
| <a name="input_rds_ca_cert_identifier"></a> [rds\_ca\_cert\_identifier](#input\_rds\_ca\_cert\_identifier) | Identifier of AWS RDS Certificate Authority Certificate | `string` | `"rds-ca-rsa2048-g1"` | no |
| <a name="input_retention_period"></a> [retention\_period](#input\_retention\_period) | Number of days to retain backups for | `number` | `34` | no |
| <a name="input_serverlessv2_config"></a> [serverlessv2\_config](#input\_serverlessv2\_config) | (OPTIONAL) Configuration for Aurora Serverless v2 (if using)<br>which specifies min/max capacity, in a range of 0.5 up to 128 in steps of 0.5.<br>If configuring a Serverless v2 cluster/instances, you MUST set<br>var.db\_engine\_mode to 'provisioned' and var.db\_instance\_class to 'db.serverless'. | <pre>list(object({<br>    max = number<br>    min = number<br>  }))</pre> | `[]` | no |
| <a name="input_storage_encrypted"></a> [storage\_encrypted](#input\_storage\_encrypted) | Whether or not to encrypt the underlying Aurora storage layer | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | n/a |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | n/a |
| <a name="output_global_cluster_arn"></a> [global\_cluster\_arn](#output\_global\_cluster\_arn) | n/a |
| <a name="output_global_cluster_id"></a> [global\_cluster\_id](#output\_global\_cluster\_id) | n/a |
| <a name="output_kms_arn"></a> [kms\_arn](#output\_kms\_arn) | n/a |
| <a name="output_log_groups"></a> [log\_groups](#output\_log\_groups) | n/a |
| <a name="output_reader_endpoint"></a> [reader\_endpoint](#output\_reader\_endpoint) | n/a |
| <a name="output_reader_instances"></a> [reader\_instances](#output\_reader\_instances) | n/a |
| <a name="output_writer_endpoint"></a> [writer\_endpoint](#output\_writer\_endpoint) | n/a |
| <a name="output_writer_instance"></a> [writer\_instance](#output\_writer\_instance) | n/a |
| <a name="output_writer_instance_az"></a> [writer\_instance\_az](#output\_writer\_instance\_az) | n/a |
| <a name="output_writer_instance_endpoint"></a> [writer\_instance\_endpoint](#output\_writer\_instance\_endpoint) | n/a |
<!-- END_TF_DOCS -->
