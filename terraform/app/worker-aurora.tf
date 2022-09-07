module "worker_aurora_uw2" {
  count  = var.worker_aurora_enabled && var.idp_aurora_enabled ? 1 : 0
  source = "../modules/rds_aurora"

  name_prefix   = var.name
  region        = "us-west-2"
  env_name      = var.env_name
  db_identifier = "idp-worker-jobs"

  # The rds_db_arn attribute should only be used when replicating from
  # the source RDS database (aws_db_instance.idp-worker-jobs).
  # Once the cluster has been promoted to standalone, this attribute can be removed,
  # and the rds_password and rds_username attributes should be used instead.
  rds_db_arn   = aws_db_instance.idp-worker-jobs.arn
  rds_password = var.rds_password_worker_jobs # ignored when creating replica
  rds_username = var.rds_username_worker_jobs # ignored when creating replica

  db_instance_class    = var.rds_instance_class_worker_jobs_aurora
  db_engine            = var.rds_engine_aurora
  db_engine_mode       = var.rds_engine_mode_aurora
  db_engine_version    = var.rds_engine_version_worker_jobs_aurora
  db_port              = var.rds_db_port
  apg_db_pgroup_params = local.apg_db_pgroup_params
  apg_cluster_pgroup_params = flatten([
    local.apg_cluster_pgroup_params,
    local.apg_param_max_standby_streaming_delay
  ])

  db_subnet_group   = aws_db_subnet_group.aurora[count.index].id
  db_security_group = aws_security_group.db.id

  retention_period    = var.rds_backup_retention_period
  backup_window       = var.rds_backup_window
  maintenance_window  = var.rds_maintenance_window
  auto_minor_upgrades = false
  major_upgrades      = true

  storage_encrypted   = true
  db_kms_key_id       = data.aws_kms_key.rds_alias.arn
  key_admin_role_name = "KMSAdministrator"

  cw_logs_exports     = ["postgresql"]
  pi_enabled          = true
  monitoring_interval = var.rds_enhanced_monitoring_interval
  monitoring_role = join(":", [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}",
    "role/${var.rds_monitoring_role_name}"
  ])

  internal_zone_id = aws_route53_zone.internal.zone_id
  route53_ttl      = 300

  primary_cluster_instances = 1                             # must start at 1, can increase once standalone
  enable_autoscaling        = var.worker_aurora_autoscaling # defaults to false

  #### must select ONE pair of variables to use, cannot use both
  #### ignored until enable_autoscaling = true

  # autoscaling_metric_name  = "RDSReaderAverageCPUUtilization"
  # autoscaling_metric_value = 40
  # autoscaling_metric_name  = "RDSReaderAverageDatabaseConnections"
  # autoscaling_metric_value = 1000
  # max_cluster_instances    = 5     # ignored until enable_autoscaling = true

  #### if using/moving to Aurora Serverless v2, this must be fully defined,
  #### var.rds_instance_class_aurora must be 'db.serverless',
  #### and var.rds_engine_mode_aurora must be 'provisioned'

  serverlessv2_config = var.worker_jobs_aurora_serverlessv2_config
}