locals {
  # This pattern is in place for current primary idp Aurora clusters in us-west-2.
  # The new default (to be used with the final DMS-migrated idp Aurora cluster)
  # should be env_name-db_identifier-region_shorthand, e.g. prod-idp-uw2,
  # which can be achieved by switching db_identifier and db_name_override below.
  idp_aurora_name = "${var.name}-${var.env_name}-idp-aurora-${var.region}"

  # This logic should help to ensure that the instance class used by the idp Aurora
  # cluster is valid for any configuration, e.g.:
  # 1. use db.t3.medium if no custom value is specified
  # 2. use var.rds_instance_class_aurora_global if var.idp_global_enabled is true
  # 3. use var.rds_instance_class_aurora if it is customized (and assume said
  #    custom version is valid for use with a global cluster)
  rds_instance_class_aurora_idp = var.rds_instance_class_aurora != "db.t3.medium" ? (
    var.rds_instance_class_aurora) : var.idp_global_enabled ? (
  var.rds_instance_class_aurora_global) : var.rds_instance_class_aurora
}

# primary cluster (us-west-2)

module "idp_aurora_uw2" {
  source = "../modules/rds_aurora"

  env_name         = var.env_name
  db_identifier    = "idp-uw2" # use instead once BigInt DMS is in place
  db_name_override = local.idp_aurora_name

  create_global_db = var.idp_global_enabled
  global_db_id     = var.idp_global_enabled ? "idp" : ""

  rds_password = var.rds_password
  rds_username = var.rds_username

  db_instance_class  = local.rds_instance_class_aurora_idp
  db_engine          = var.rds_engine_aurora
  db_engine_mode     = var.rds_engine_mode_aurora
  db_engine_version  = var.rds_engine_version_aurora
  db_port            = var.rds_db_port
  apg_db_pgroup      = module.idp_rds_usw2.aurora_db_pgroup
  apg_cluster_pgroup = module.idp_rds_usw2.aurora_cluster_pgroup

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
  key_admin_role_name = "KMSAdministrator"

  cw_logs_exports     = ["postgresql"]
  pi_enabled          = true
  monitoring_interval = var.rds_enhanced_monitoring_interval
  monitoring_role = join(":", [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}",
    "role/${var.rds_monitoring_role_name}"
  ])

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
  #### local.rds_instance_class_aurora_idp must be 'db.serverless',
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

module "idp_aurora_cloudwatch" {
  source = "../modules/cloudwatch_rds/"

  type                          = "aurora"
  rds_storage_threshold         = var.rds_storage_threshold
  rds_db                        = module.idp_aurora_uw2.writer_instance
  alarm_actions                 = local.low_priority_alarm_actions
  unvacummed_transactions_count = var.unvacummed_transactions_count
  db_instance_class             = local.rds_instance_class_aurora_idp
}

# secondary cluster (us-east-1)

module "idp_aurora_ue1" {
  count  = var.idp_global_enabled && var.idp_aurora_ue1_enabled ? 1 : 0
  source = "../modules/rds_aurora"
  providers = {
    aws = aws.use1
  }

  env_name      = var.env_name
  db_identifier = "idp-ue1"

  # ensure that this is created as a replica within the global cluster above
  create_global_db = false
  global_db_id     = module.idp_aurora_uw2.global_cluster_id

  rds_password = "" # do not set in replica cluster
  rds_username = "" # do not set in replica cluster

  db_instance_class  = local.rds_instance_class_aurora_idp
  db_engine          = var.rds_engine_aurora
  db_engine_mode     = var.rds_engine_mode_aurora
  db_engine_version  = var.rds_engine_version_aurora
  db_port            = var.rds_db_port
  apg_db_pgroup      = module.idp_rds_use1[0].aurora_db_pgroup
  apg_cluster_pgroup = module.idp_rds_use1[0].aurora_cluster_pgroup

  db_subnet_group        = module.network_use1[count.index].db_subnet_group
  db_security_group      = module.network_use1[count.index].db_security_group
  db_publicly_accessible = local.nessus_public_access_mode

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
  #### local.rds_instance_class_aurora_idp must be 'db.serverless',
  #### and var.rds_engine_mode_aurora must be 'provisioned'

  serverlessv2_config = var.idp_aurora_serverlessv2_config

  depends_on = [module.idp_aurora_uw2.global_cluster_id]
}

module "idp_rds_use1" {
  count  = var.rds_recover_to_ue1 || var.idp_aurora_ue1_enabled ? 1 : 0
  source = "../modules/idp_rds"
  providers = {
    aws = aws.use1
  }
  env_name              = var.env_name
  db_identifier         = "idp-ue1"
  db_engine             = var.rds_engine_aurora
  db_engine_version     = var.rds_engine_version_aurora
  cluster_pgroup_params = local.apg_cluster_pgroup_params
  db_pgroup_params      = local.apg_db_pgroup_params
}

# disaster recovery cluster (us-west-2)

module "dr_restore_idp_aurora" {
  count = var.dr_restore_idp_db && (
    (var.dr_restore_type == "snapshot" && var.dr_snapshot_identifier != "") || (
  var.dr_restore_type == "point-in-time" && var.dr_restore_to_time != "")) ? 1 : 0

  source = "../modules/rds_aurora"

  dr_snapshot_identifier       = var.dr_snapshot_identifier
  dr_restore_type              = var.dr_restore_type
  dr_source_cluster_identifier = "${var.env_name}-idp-uw2"
  dr_restore_to_time           = var.dr_restore_to_time

  env_name = var.env_name

  db_identifier = "idp-aurora-restored"

  rds_password = var.rds_password
  rds_username = var.rds_username

  db_instance_class  = local.rds_instance_class_aurora_idp
  db_engine          = var.rds_engine_aurora
  db_engine_mode     = var.rds_engine_mode_aurora
  db_engine_version  = var.rds_engine_version_aurora
  db_port            = var.rds_db_port
  apg_db_pgroup      = module.idp_rds_usw2.aurora_db_pgroup
  apg_cluster_pgroup = module.idp_rds_usw2.aurora_cluster_pgroup

  db_subnet_group        = module.network_uw2.db_subnet_group
  db_security_group      = module.network_uw2.db_security_group
  db_publicly_accessible = local.nessus_public_access_mode

  retention_period    = var.rds_backup_retention_period
  backup_window       = var.rds_backup_window
  maintenance_window  = var.rds_maintenance_window
  auto_minor_upgrades = false
  major_upgrades      = true

  storage_encrypted   = true
  db_kms_key_id       = module.idp_aurora_uw2.kms_arn
  key_admin_role_name = "KMSAdministrator"

  cw_logs_exports     = ["postgresql"]
  pi_enabled          = true
  monitoring_interval = var.rds_enhanced_monitoring_interval
  monitoring_role = join(":", [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}",
    "role/${var.rds_monitoring_role_name}"
  ])

  primary_cluster_instances = 1
  enable_autoscaling        = false

  serverlessv2_config = var.idp_aurora_serverlessv2_config
}