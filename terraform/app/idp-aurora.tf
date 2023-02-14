locals {
  # This pattern is in place for current idp Aurora clusters. The new default
  # (to be used with the final DMS-migrated idp Aurora cluster) should
  # be env_name-db_identifier, e.g. prod-idp, since the region name will still
  # be included in the full endpoint address.
  idp_aurora_name = "${var.name}-${var.env_name}-idp-aurora-${var.region}"
}

module "idp_aurora_from_rds" {
  count  = var.idp_aurora_enabled ? 1 : 0 # keep until BigInt migration is done
  source = "../modules/rds_aurora"

  region   = "us-west-2"
  env_name = var.env_name

  # switch once BigInt migration is done + remove db_name_override
  #db_identifier = "idp"
  db_identifier    = "idp-aurora"
  db_name_override = local.idp_aurora_name

  rds_password = var.rds_password
  rds_username = var.rds_username

  db_instance_class  = var.rds_instance_class_aurora
  db_engine          = var.rds_engine_aurora
  db_engine_mode     = var.rds_engine_mode_aurora
  db_engine_version  = var.rds_engine_version_aurora
  db_port            = var.rds_db_port
  apg_db_pgroup      = module.idp_rds_usw2.aurora_db_pgroup
  apg_cluster_pgroup = module.idp_rds_usw2.aurora_cluster_pgroup

  db_subnet_group        = aws_db_subnet_group.aurora.id
  db_security_group      = aws_security_group.db.id
  db_publicly_accessible = local.nessus_public_access_mode

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

  primary_cluster_instances = var.idp_cluster_instances  # MUST start at 1
  enable_autoscaling        = var.idp_aurora_autoscaling # defaults to false

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

  serverlessv2_config = var.idp_aurora_serverlessv2_config
}

# set up Aurora instance/cluster parameter groups + idp-rds KMS CMK

module "idp_rds_usw2" {
  source = "../modules/idp_rds"
  providers = {
    aws = aws.usw2
  }
  env_name              = var.env_name
  db_name_override      = local.idp_aurora_name
  db_engine             = var.rds_engine_aurora
  db_engine_version     = var.rds_engine_version_aurora
  cluster_pgroup_params = local.apg_cluster_pgroup_params
  db_pgroup_params      = local.apg_db_pgroup_params
}

module "idp_rds_use1" {
  count  = var.rds_recover_to_ue1 ? 1 : 0
  source = "../modules/idp_rds"
  providers = {
    aws = aws.use1
  }
  env_name              = var.env_name
  db_name_override      = local.idp_aurora_name
  db_engine             = var.rds_engine_aurora
  db_engine_version     = var.rds_engine_version_aurora
  cluster_pgroup_params = local.apg_cluster_pgroup_params
  db_pgroup_params      = local.apg_db_pgroup_params
}

module "idp_aurora_cloudwatch" {
  count  = var.idp_aurora_enabled ? 1 : 0
  source = "../modules/cloudwatch_rds/"

  type                          = "aurora"
  rds_storage_threshold         = var.rds_storage_threshold
  rds_db                        = module.idp_aurora_from_rds[count.index].writer_instance
  alarm_actions                 = local.low_priority_alarm_actions
  unvacummed_transactions_count = var.unvacummed_transactions_count
  db_instance_class             = var.rds_instance_class_aurora
}
