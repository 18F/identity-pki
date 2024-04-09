module "dashboard_aurora_uw2" {
  count  = var.apps_enabled
  source = "../modules/rds_aurora"

  env_name          = var.env_name
  db_identifier     = "dashboard"
  rds_password      = var.rds_password
  rds_username      = var.rds_username
  db_instance_class = var.rds_instance_class_dashboard
  db_engine         = var.rds_engine
  db_engine_mode    = var.rds_engine_mode
  db_engine_version = var.rds_engine_version_uw2
  db_port           = var.rds_db_port

  # use default parameter groups, as per original apps db
  apg_cluster_pgroup = var.dashboard_aurora_pgroup
  apg_db_pgroup      = var.dashboard_aurora_pgroup

  db_subnet_group        = module.network_uw2.db_subnet_group
  db_security_group      = module.network_uw2.db_security_group
  db_publicly_accessible = local.nessus_public_access_mode
  rds_ca_cert_identifier = var.rds_ca_cert_identifier

  retention_period    = var.rds_backup_retention_period
  backup_window       = var.rds_backup_window
  maintenance_window  = var.rds_maintenance_window
  auto_minor_upgrades = false
  major_upgrades      = true

  storage_encrypted   = true
  db_kms_key_id       = module.idp_aurora_uw2.kms_arn
  key_admin_role_name = "KMSAdministrator"

  cw_logs_exports           = ["postgresql"]
  cloudwatch_retention_days = local.retention_days
  pi_enabled                = true
  monitoring_interval       = var.rds_enhanced_monitoring_interval
  monitoring_role = join(":", [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}",
    "role/${var.rds_monitoring_role_name}"
  ])

  primary_cluster_instances = var.dashboard_cluster_instances  # must start at 1
  enable_autoscaling        = var.dashboard_aurora_autoscaling # defaults to false

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

  serverlessv2_config = var.dashboard_aurora_serverlessv2_config
}

module "dashboard_aurora_uw2_cloudwatch" {
  count  = var.apps_enabled
  source = "../modules/cloudwatch_rds/"

  type                          = "aurora"
  rds_storage_threshold         = var.rds_storage_threshold
  rds_db                        = module.dashboard_aurora_uw2[count.index].writer_instance
  alarm_actions                 = local.moderate_priority_alarm_actions
  unvacummed_transactions_count = var.unvacummed_transactions_count
  db_instance_class             = var.rds_instance_class_dashboard
}
