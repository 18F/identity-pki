resource "aws_db_subnet_group" "aurora" {
  name        = "analytics-rds-${var.env_name}"
  description = "RDS Aurora Subnet Group for ${var.env_name} environment"
  subnet_ids  = [for subnet in aws_subnet.data-services : subnet.id]
}

module "analytics_aurora" {
  source = "../../modules/rds_aurora"

  env_name      = var.env_name
  db_identifier = "analytics"

  rds_password = var.rds_password
  rds_username = var.rds_username

  db_instance_class  = var.rds_instance_class
  db_engine          = var.rds_engine
  db_engine_mode     = var.rds_engine_mode
  db_engine_version  = var.rds_engine_version
  db_port            = var.rds_db_port
  apg_db_pgroup      = module.analytics_aurora_rds.aurora_db_pgroup
  apg_cluster_pgroup = module.analytics_aurora_rds.aurora_cluster_pgroup

  db_subnet_group        = aws_db_subnet_group.aurora.id
  db_security_group      = aws_security_group.db.id
  db_publicly_accessible = local.nessus_public_access_mode
  rds_ca_cert_identifier = var.rds_ca_cert_identifier

  retention_period    = var.rds_backup_retention_period
  backup_window       = var.rds_backup_window
  maintenance_window  = var.rds_maintenance_window
  auto_minor_upgrades = false
  major_upgrades      = true

  storage_encrypted   = true
  key_admin_role_name = "KMSAdministrator"

  cw_logs_exports     = ["postgresql"]
  pi_enabled          = true
  monitoring_interval = var.rds_enhanced_monitoring_interval
  monitoring_role = join(":", [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}",
    "role/${var.rds_monitoring_role_name}"
  ])

  primary_cluster_instances = var.analytics_cluster_instances  # MUST start at 1
  enable_autoscaling        = var.analytics_aurora_autoscaling # defaults to false

  #### must select ONE pair of variables to use, cannot use both
  #### ignored until enable_autoscaling = true

  # autoscaling_metric_name  = "RDSReaderAverageCPUUtilization"
  # autoscaling_metric_value = 40
  # autoscaling_metric_name  = "RDSReaderAverageDatabaseConnections"
  # autoscaling_metric_value = 1000
  # max_cluster_instances    = 5     # ignored until enable_autoscaling = true

  #### if using/moving to Aurora Serverless v2, this must be fully defined,
  #### var.rds_instance_class must be 'db.serverless',
  #### and var.rds_engine_mode must be 'provisioned'

  serverlessv2_config = var.analytics_serverlessv2_config
}

# set up Aurora instance/cluster parameter groups + analytics-rds KMS CMK

module "analytics_aurora_rds" {
  source = "../../modules/idp_rds"
  providers = {
    aws = aws.usw2
  }
  env_name              = var.env_name
  db_engine             = var.rds_engine
  db_engine_version     = var.rds_engine_version
  cluster_pgroup_params = local.apg_cluster_pgroup_params
  db_pgroup_params      = local.apg_db_pgroup_params
}

module "analytics_aurora_cloudwatch" {
  source = "../../modules/cloudwatch_rds/"

  type                            = "aurora"
  rds_storage_threshold           = var.rds_storage_threshold
  rds_db                          = module.analytics_aurora.writer_instance
  alarm_actions                   = local.low_priority_alarm_actions
  unvacummed_transactions_count   = var.unvacummed_transactions_count
  db_instance_class               = var.rds_instance_class
  rds_aurora_alarm_threshold_iops = 5000
}

