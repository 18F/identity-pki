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
  db_instance_class         = var.rds_instance_class_aurora
  db_engine                 = var.rds_engine_aurora
  db_engine_version         = var.rds_engine_version_aurora
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

## Variables

Custom variable values ***must be declared*** if they default to a blank/empty value (e.g. `""`, `[]`) in the table below (unless otherwise specified).

| Category                     | Name                         | Description                                                                                                                                                                                                        | Default                                                                                                  |
| :--------------------------- | :--------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------- |
| Identifiers                  | `region`                     | Primary AWS Region                                                                                                                                                                                                 | `us-west-2`                                                                                              |
| Identifiers                  | `name_prefix`                | Prefix for resource names                                                                                                                                                                                          | `login`                                                                                                  |
| Identifiers                  | `env_name`                   | Environment name                                                                                                                                                                                                   | ""                                                                                                       |
| Identifiers                  | `db_identifier`              | Unique identifier for the database (e.g. `default`/`primary`/etc.)                                                                                                                                                 | ""                                                                                                       |
| Identifiers                  | `rds_db_arn`                 | ARN of RDS DB used as replication source for the Aurora cluster; leave blank if not using an RDS replication source / creating a standalone cluster                                                                | ""                                                                                                       |
| DB Engine / Parameter Config | `db_engine`                  | AuroraDB engine name (`aurora`/`aurora-mysql`/`aurora-postgresql`)                                                                                                                                                 | `aurora-postgresql`                                                                                      |
| DB Engine / Parameter Config | `db_engine_version`          | Version number (e.g. ##.#) of db_engine to use                                                                                                                                                                     | `13.5`                                                                                                   |
| DB Engine / Parameter Config | `db_port`                    | Database port number                                                                                                                                                                                               | **5432**                                                                                                 |
| DB Engine / Parameter Config | `apg_db_pgroup_params`       | List of parameters to configure for the AuroraDB parameter group                                                                                                                                                   | []                                                                                                       |
| DB Engine / Parameter Config | `apg_cluster_pgroup_params`  | List of parameters to configure for the AuroraDB cluster parameter group                                                                                                                                           | []                                                                                                       |
| Engine Mode / Instance Class | `db_engine_mode`             | Engine mode for the AuroraDB cluster. Must be `global`, `multimaster`, `parallelquery`, `provisioned`, or `serverless`                                                                                             | `provisioned`                                                                                            |
| Engine Mode / Instance Class | `db_instance_class`          | Instance class to use in AuroraDB cluster                                                                                                                                                                          | `db.r5.large`                                                                                            |
| Engine Mode / Instance Class | `serverlessv2_config`        | Config for Aurora Serverless v2 (if using) which specifies min/max capacity, from 0.5 to 128 in steps of 0.5; MUST set var.db_engine_mode to 'provisioned' and var.db_instance_class to 'db.serverless' if using   | []                                                                                                       |
| Read Replicas / Auto Scaling | `primary_cluster_instances`  | Number of instances to create for the primary AuroraDB cluster; MUST be Set to 1 if creating cluster as a read replica and then should be set to 2+ thereafter                                                     | **2**                                                                                                    |
| Read Replicas / Auto Scaling | `enable_autoscaling`         | Whether or not to enable Auto Scaling of read replica instances                                                                                                                                                    | *false*                                                                                                  |
| Read Replicas / Auto Scaling | `max_cluster_instances`      | Maximum number of read replica instances to scale up to (if enabling Auto Scaling for the Aurora cluster)                                                                                                          | **5**                                                                                                    |
| Read Replicas / Auto Scaling | `autoscaling_metric_name`    | Name of the predefined metric used by the Auto Scaling policy (if enabling Auto Scaling for the Aurora cluster)                                                                                                    | ""                                                                                                       |
| Read Replicas / Auto Scaling | `autoscaling_metric_value`   | Desired target value of Auto Scaling policy's predefined metric (if enabling Auto Scaling for the Aurora cluster)                                                                                                  | **40**                                                                                                   |
| Logging / Monitoring         | `cw_logs_exports`            | List of log types to export to CloudWatch (will use `["general"]` if not specified or `["postgresql"]` if `var.db_engine` is `"aurora-postgresql"`                                                                 | []                                                                                                       |
| Logging / Monitoring         | `pi_enabled`                 | Whether or not to enable Performance Insights on the Aurora cluster                                                                                                                                                | *true*                                                                                                   |
| Logging / Monitoring         | `monitoring_interval`        | Time (in seconds) to wait before each metric sample collection; disabled if set to 0                                                                                                                               | **60**                                                                                                   |
| Logging / Monitoring         | `monitoring_role`            | Name of an existing IAM role with the `AmazonRDSEnhancedMonitoringRole` service role policy attached; will create the `rds_monitoring` IAM role (which has said permission) if this value is left blank            | ""                                                                                                       |
| Maintenance / Upgrades       | `auto_minor_upgrades`        | Whether or not to perform minor engine upgrades automatically during the specified in the maintenance window                                                                                                       | *false*                                                                                                  |
| Maintenance / Upgrades       | `major_upgrades`             | Whether or not to allow performing major version upgrades when changing engine versions                                                                                                                            | *true*                                                                                                   |
| Maintenance / Upgrades       | `retention_period`           | Number of days to retain backups for                                                                                                                                                                               | **34**                                                                                                   |
| Maintenance / Upgrades       | `backup_window`              | Daily time range (in UTC) for automated backups                                                                                                                                                                    | `08:00-08:34`                                                                                            |
| Maintenance / Upgrades       | `maintenance_window`         | Weekly time range (in UTC) for scheduled/system maintenance                                                                                                                                                        | `Sun:08:34-Sun:09:08`                                                                                    |
| Networking                   | `db_security_group`          | VPC Security Group ID used by the AuroraDB cluster                                                                                                                                                                 | ""                                                                                                       |
| Networking                   | `db_subnet_group`            | Name of private subnet group in the `var.region` VPC                                                                                                                                                               | ""                                                                                                       |
| Security / KMS               | `storage_encrypted`          | Whether or not to encrypt the underlying Aurora storage layer                                                                                                                                                      | true                                                                                                     |
| Security / KMS               | `db_kms_key_id`              | ID of an already-existing KMS Key used to encrypt the database; will create the `aws_kms_key.db` / `aws_kms_alias.db` resources and use those for encryption if left blank                                         | ""                                                                                                       |
| Security / KMS               | `key_admin_role_name`        | Name of an external IAM role to be granted permissions to interact with the KMS key used for encrypting the database                                                                                               | ""                                                                                                       |
| Security / KMS               | `rds_password`               | Password for the RDS master user account                                                                                                                                                                           | ""                                                                                                       |
| Security / KMS               | `rds_username`               | Username for the RDS master user account                                                                                                                                                                           | ""                                                                                                       |
| DNS / Route53                | `internal_zone_id`           | ID of the Route53 hosted zone to create records in                                                                                                                                                                 | ""                                                                                                       |
| DNS / Route53                | `route53_ttl`                | TTL for the Route53 DNS records for the writer/reader endpoints                                                                                                                                                    | **300**                                                                                                  |
