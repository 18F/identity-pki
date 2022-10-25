resource "aws_db_instance" "idp" {
  count = var.idp_use_rds ? 1 : 0

  allocated_storage       = var.rds_storage_idp
  backup_retention_period = var.rds_backup_retention_period
  backup_window           = var.rds_backup_window
  db_subnet_group_name    = aws_db_subnet_group.default.id
  engine                  = var.rds_engine
  engine_version          = var.rds_engine_version
  identifier              = "${var.name}-${var.env_name}-idp"
  instance_class          = var.rds_instance_class
  maintenance_window      = var.rds_maintenance_window
  multi_az                = true
  parameter_group_name    = module.idp_rds_usw2.rds_parameter_group_name
  password                = var.rds_password # change this by hand after creation
  storage_encrypted       = true
  username                = var.rds_username
  storage_type            = var.rds_storage_type_idp
  iops                    = var.rds_iops_idp

  # we want to push these via Terraform now
  auto_minor_version_upgrade  = false
  allow_major_version_upgrade = true
  apply_immediately           = true

  tags = {
    Name = "${var.name}-${var.env_name}"
  }

  # enhanced monitoring
  monitoring_interval             = var.rds_enhanced_monitoring_interval
  monitoring_role_arn             = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.rds_monitoring_role_name}"
  performance_insights_enabled    = var.performance_insights_enabled
  performance_insights_kms_key_id = var.performance_insights_enabled ? data.aws_kms_key.rds_alias.arn : ""

  vpc_security_group_ids = [aws_security_group.db.id]

  # send logs to cloudwatch
  enabled_cloudwatch_logs_exports = ["postgresql"]

  # If you want to destroy your database, you need to do this in two phases:
  # 1. Uncomment `skip_final_snapshot=true` and
  #    comment `prevent_destroy=true` and `deletion_protection = true` below.
  # 2. Perform a terraform/deploy "apply" with the additional
  #    argument of "-target=aws_db_instance.idp" to mark the database
  #    as not requiring a final snapshot.
  # 3. Perform a terraform/deploy "destroy" as needed.
  #
  #skip_final_snapshot = true
  lifecycle {
    prevent_destroy = true

    # we set the password by hand so it doesn't end up in the state file
    ignore_changes = [password]
  }

  deletion_protection = true
}

module "idp_cloudwatch_rds" {
  count  = var.idp_use_rds ? 1 : 0
  source = "../modules/cloudwatch_rds/"

  rds_storage_threshold         = var.rds_storage_threshold
  rds_db                        = aws_db_instance.idp[count.index].id
  alarm_actions                 = local.low_priority_alarm_actions
  unvacummed_transactions_count = var.unvacummed_transactions_count
  db_instance_class             = var.rds_instance_class
}

data "aws_sns_topic" "rds_snapshot_events" {
  name = "rds-snapshot-events"
}

# Optional read replica of the primary idp database
resource "aws_db_instance" "idp-read-replica" {
  count               = var.enable_rds_idp_read_replica && var.idp_use_rds ? 1 : 0
  replicate_source_db = aws_db_instance.idp[count.index].id

  identifier = "${var.env_name}-idp-replica"

  tags = {
    Name        = "${var.env_name}-idp-replica"
    description = "Read replica of idp database"
  }

  instance_class       = var.rds_instance_class_replica
  parameter_group_name = module.idp_rds_usw2.rds_parameter_group_name

  multi_az = false

  auto_minor_version_upgrade  = false
  allow_major_version_upgrade = true
  apply_immediately           = true

  maintenance_window = var.rds_maintenance_window
  storage_encrypted  = true
  storage_type       = var.rds_storage_type_idp_replica
  allocated_storage  = var.rds_storage_idp_replica
  iops               = var.rds_iops_idp_replica

  # enhanced monitoring
  monitoring_interval             = var.rds_enhanced_monitoring_interval
  monitoring_role_arn             = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.rds_monitoring_role_name}"
  performance_insights_enabled    = var.performance_insights_enabled
  performance_insights_kms_key_id = var.performance_insights_enabled ? data.aws_kms_key.rds_alias.arn : ""

  vpc_security_group_ids = [aws_security_group.db.id]

  # send logs to cloudwatch
  enabled_cloudwatch_logs_exports = ["postgresql"]

  # uncomment this if deleting the read replica / environment
  #skip_final_snapshot = true
}

module "idp_replica_cloudwatch_rds" {
  source = "../modules/cloudwatch_rds/"
  count  = var.enable_rds_idp_read_replica && var.idp_use_rds ? 1 : 0

  rds_storage_threshold = var.rds_storage_threshold
  rds_db                = aws_db_instance.idp-read-replica[count.index].id
  alarm_actions         = local.low_priority_alarm_actions
}

module "idp_rds_usw2" {
  source = "../modules/idp_rds"
  providers = {
    aws = aws.usw2
  }
  env_name           = var.env_name
  name               = var.name
  rds_engine         = var.rds_engine
  rds_engine_version = var.rds_engine_version
  #pgroup_params = [] # uncomment when turning down RDS database
  pgroup_params = flatten([
    local.apg_cluster_pgroup_params,
    local.apg_db_pgroup_params,
    local.rds_param_max_standby_streaming_delay
  ])
}

module "idp_rds_use1" {
  count  = var.idp_use_rds && var.rds_recover_to_ue1 ? 1 : 0
  source = "../modules/idp_rds"
  providers = {
    aws = aws.use1
  }
  env_name           = var.env_name
  name               = var.name
  rds_engine         = var.rds_engine
  rds_engine_version = var.rds_engine_version
  #pgroup_params = [] # uncomment when turning down RDS database
  pgroup_params = flatten([
    local.apg_cluster_pgroup_params,
    local.apg_db_pgroup_params,
    local.rds_param_max_standby_streaming_delay
  ])
}

resource "aws_route53_record" "idp-postgres" {
  count   = var.idp_use_rds ? 1 : 0
  zone_id = aws_route53_zone.internal.zone_id
  name    = "idp-postgres"

  type    = "CNAME"
  ttl     = "300"
  records = [replace(aws_db_instance.idp[count.index].endpoint, ":${var.rds_db_port}", "")]
}
