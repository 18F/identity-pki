##### Data Sources

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "region" {
  state = "available"
}

# use aws/rds KMS key for cluster encryption + performance insights
data "aws_kms_key" "rds_alias" {
  key_id = "alias/aws/rds"
}

##### Resources

# Monitoring

resource "aws_iam_role" "rds_monitoring" {
  count = var.monitoring_role == "" ? 1 : 0 # create if not importing
  name  = "rds-monitoring-role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "monitoring.rds.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count      = var.monitoring_role == "" ? 1 : 0
  role       = aws_iam_role.rds_monitoring[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_cloudwatch_log_group" "aurora" {
  for_each = toset(local.cw_logs)

  name              = "/aws/rds/cluster/${local.db_name}/${each.key}"
  retention_in_days = var.cloudwatch_retention_days
}

# Global Cluster 'head' resource

resource "aws_rds_global_cluster" "aurora" {
  count = var.create_global_db ? 1 : 0

  global_cluster_identifier    = "${var.env_name}-${var.global_db_id}"
  source_db_cluster_identifier = aws_rds_cluster.aurora.arn
  force_destroy                = true

  # To properly delete this cluster via Terraform:
  # 1. Comment out the `deletion_protection` and `lifecycle/prevent_destroy` lines.
  # 2. Perform a targeted 'apply' (e.g. "-target=aws_rds_global_cluster.aurora")
  #    to remove deletion protection + disable requiring a final snapshot.
  # 3. Perform a 'destroy' operation as needed.

  deletion_protection = true

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [source_db_cluster_identifier]
  }

  depends_on = [aws_rds_cluster.aurora]
}

# AuroraDB Cluster + Instances

resource "aws_rds_cluster" "aurora" {
  cluster_identifier = local.db_name
  engine             = var.db_engine
  engine_version     = var.db_engine_version
  engine_mode        = var.db_engine_mode
  port               = var.db_port
  database_name      = var.db_identifier
  availability_zones = [
    for i in range(0, 3) : data.aws_availability_zones.region.names[i]
  ]

  db_subnet_group_name             = var.db_subnet_group
  vpc_security_group_ids           = [var.db_security_group]
  db_cluster_parameter_group_name  = var.apg_cluster_pgroup
  db_instance_parameter_group_name = var.apg_db_pgroup

  backup_retention_period      = var.retention_period
  preferred_backup_window      = var.backup_window
  preferred_maintenance_window = var.maintenance_window
  allow_major_version_upgrade  = var.major_upgrades
  apply_immediately            = true

  storage_encrypted = var.storage_encrypted
  master_password   = var.rds_password
  master_username   = var.rds_username
  kms_key_id = (
    var.db_kms_key_id == "" ? data.aws_kms_key.rds_alias.arn : var.db_kms_key_id
  )

  # only use if NOT creating Global cluster ; must specify external Global cluster ID
  global_cluster_identifier = var.global_db_id != "" && var.create_global_db == false ? (
  var.global_db_id) : null

  # send logs to cloudwatch
  enabled_cloudwatch_logs_exports = local.cw_logs

  copy_tags_to_snapshot = var.copy_tags_to_snapshot

  tags = {
    Name = local.db_name
  }

  # only create Serverless v2 configuration if it is defined +
  # using db.serverless instance class + provisioned db_engine_mode
  dynamic "serverlessv2_scaling_configuration" {
    for_each = (
      var.db_instance_class == "db.serverless" && var.db_engine_mode == "provisioned" ? (
      var.serverlessv2_config) : []
    )
    iterator = sv2config

    content {
      max_capacity = sv2config.value.max
      min_capacity = sv2config.value.min
    }
  }

  snapshot_identifier = (
    var.dr_restore_type == "snapshot" && var.dr_snapshot_identifier != "" ? (
    var.dr_snapshot_identifier) : null
  )

  dynamic "restore_to_point_in_time" {
    for_each = var.dr_restore_type == "point-in-time" && var.dr_restore_to_time != "" ? [1] : []
    content {
      source_cluster_identifier = var.dr_source_cluster_identifier
      restore_type              = "full-copy"
      restore_to_time           = var.dr_restore_to_time
    }
  }

  # To properly delete this cluster via Terraform:
  # 1. Comment out the `deletion_protection` and `lifecycle/prevent_destroy` lines,
  #    and uncomment the `skip_final_snapshot` line, below
  # 2. Perform a targeted 'apply' (e.g. "-target=aws_rds_cluster.aurora")
  #    to remove deletion protection + disable requiring a final snapshot.
  # 3. Perform a 'destroy' operation as needed.

  #skip_final_snapshot = true
  deletion_protection = true

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      replication_source_identifier,
      global_cluster_identifier,
      master_password,
      master_username,
      kms_key_id,
      availability_zones
    ]
  }

  depends_on = [aws_cloudwatch_log_group.aurora]
}

resource "aws_rds_cluster_instance" "aurora" {
  count      = var.primary_cluster_instances # must be 1 on first creation
  identifier = "${local.db_name}-${count.index + 1}"

  ca_cert_identifier   = var.rds_ca_cert_identifier
  cluster_identifier   = aws_rds_cluster.aurora.id
  engine               = var.db_engine
  engine_version       = var.db_engine_version
  db_subnet_group_name = var.db_subnet_group
  instance_class       = var.db_instance_class
  publicly_accessible  = var.db_publicly_accessible

  db_parameter_group_name = var.apg_db_pgroup

  tags = {
    Name = local.db_name
  }

  auto_minor_version_upgrade   = var.auto_minor_upgrades
  apply_immediately            = true
  preferred_maintenance_window = var.maintenance_window

  # enhanced monitoring
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_role

  # performance insights
  performance_insights_enabled = var.pi_enabled
  performance_insights_kms_key_id = (
    var.pi_enabled ? data.aws_kms_key.rds_alias.arn : ""
  )

  lifecycle {
    ignore_changes = [
      performance_insights_kms_key_id
    ]
  }
}

# Application Auto Scaling (if desired)

resource "aws_appautoscaling_target" "db" {
  count = var.enable_autoscaling && var.primary_cluster_instances > 1 ? 1 : 0

  max_capacity       = var.max_cluster_instances
  min_capacity       = var.primary_cluster_instances
  resource_id        = "cluster:${aws_rds_cluster.aurora.id}"
  scalable_dimension = "rds:cluster:ReadReplicaCount"
  service_namespace  = "rds"
}

resource "aws_appautoscaling_policy" "db" {
  count = var.enable_autoscaling && var.primary_cluster_instances > 1 ? 1 : 0
  name = join(":", [
    aws_appautoscaling_target.db[count.index].resource_id,
    replace(var.autoscaling_metric_name, "RDSReaderAverage", ""),
    "ReplicaScalingPolicy"
  ])

  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.db[count.index].resource_id
  scalable_dimension = aws_appautoscaling_target.db[count.index].scalable_dimension
  service_namespace  = aws_appautoscaling_target.db[count.index].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = var.autoscaling_metric_name
    }

    target_value = var.autoscaling_metric_value
  }
}
