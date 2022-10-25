locals {
  free_space_type = var.type == "rds" ? "Database free" : "Cluster instance temporary"

  rds_alarms_map = {
    highDiskQueueDepth = {
      comparison_operator = "GreaterThanThreshold"
      metric_name         = "DiskQueueDepth"
      threshold           = 20
      alarm_description   = <<EOM
Average database disk queue depth is too high, performance may be negatively impacted

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-RDS-disk-queue-depth
EOM
    },
    lowFreeStorageSpace = {
      comparison_operator = "LessThanThreshold"
      metric_name         = var.type == "rds" ? "FreeStorageSpace" : "FreeLocalStorage"
      threshold           = var.rds_storage_threshold
      alarm_description   = <<EOM
${local.free_space_type} storage is too low and may fill up soon!

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-RDS-PostgreSQL-General#storage-volumes
EOM
    },
    readIOPStoohigh = {
      comparison_operator = "GreaterThanThreshold"
      metric_name         = "ReadIOPS"
      threshold           = 2500
      alarm_description   = <<EOM
ReadIOPS is too high. Check RDS Instance and consider provisioned IOPS adjustment

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-RDS-PostgreSQL-General#iops
EOM
    },
    writeIOPStoohigh = {
      comparison_operator = "GreaterThanThreshold"
      metric_name         = "WriteIOPS"
      threshold           = 2500
      alarm_description   = <<EOM
Write IOPS is too high. Check RDS Instance and consider provisioned IOPS adjustment

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-RDS-PostgreSQL-General#iops
EOM
    },
    MaximumUsedTransactionIDstoohigh = {
      comparison_operator = "GreaterThanThreshold"
      metric_name         = "MaximumUsedTransactionIDs"
      threshold           = var.unvacummed_transactions_count
      alarm_description   = <<EOM
Usage of Transaction IDs in PostgreSQL Database is high -
Check RDS Instance, review and cleanup the unvacuumed transactions before the autovacuum kicks in

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-RDS-PostgreSQL-Optimization#vacuum-deep-dive
EOM
    },
    HighNetworkThroughput = {
      comparison_operator = "GreaterThanThreshold"
      metric_name         = "NetworkThroughput"
      threshold           = local.rds_instance_network_performance[var.db_instance_class] * 1000000000 * 0.7
      alarm_description   = <<EOM
Network Utilization in PostgreSQL Data is high -
Check RDS Instance, evalutate network usage and resize if necessary.

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-RDS-PostgreSQL-General
EOM
    },
    CriticalNetworkThroughput = {
      comparison_operator = "GreaterThanThreshold"
      metric_name         = "NetworkThroughput"
      threshold           = local.rds_instance_network_performance[var.db_instance_class] * 1000000000 * 0.9
      alarm_description   = <<EOM
Network Utilization in PostgreSQL Data is Critical -
Check RDS Instance, evalutate network usage and resize if necessary.

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-RDS-PostgreSQL-General
EOM
    },
  }

  # Terraform can't determine the network capablity of each node type.
  # This is a map of nodes types to GB/s.
  rds_instance_network_performance = {
    "db.x2g.16xlarge" = 3.125
    "db.x2g.12xlarge" = 2.5
    "db.x2g.8xlarge"  = 1.5
    "db.x2g.4xlarge"  = 1.25
    "db.x2g.2xlarge"  = 1.25
    "db.x2g.xlarge"   = 1.25
    "db.x2g.large"    = 1.25
    "db.r6g.16xlarge" = 3.125
    "db.r6g.12xlarge" = 2.5
    "db.r6g.8xlarge"  = 1.5
    "db.r6g.4xlarge"  = 1.25
    "db.r6g.2xlarge"  = 1.25
    "db.r6g.xlarge"   = 1.25
    "db.r6g.large"    = 1.25
    "db.r6i.32xlarge" = 6.25
    "db.r6i.24xlarge" = 4.6875
    "db.r6i.16xlarge" = 3.125
    "db.r6i.12xlarge" = 2.34375
    "db.r6i.8xlarge"  = 1.5625
    "db.r6i.4xlarge"  = 1.5625
    "db.r6i.2xlarge"  = 1.5625
    "db.r6i.xlarge"   = 1.5625
    "db.r6i.large"    = 1.5625
    "db.r5.24xlarge"  = 3.125
    "db.r5.16xlarge"  = 2.5
    "db.r5.12xlarge"  = 1.25
    "db.r5.8xlarge"   = 1.25
    "db.r5.4xlarge"   = 1.25
    "db.r5.2xlarge"   = 1.25
    "db.r5.xlarge"    = 1.25
    "db.r5.large"     = 1.25
    "db.r4.16xlarge"  = 3.125
    "db.r4.8xlarge"   = 1.25
    "db.r4.4xlarge"   = 1.25
    "db.r4.2xlarge"   = 1.25
    "db.r4.xlarge"    = 1.25
    "db.r4.large"     = 1.25
    "db.r3.8xlarge"   = 1.25
    "db.t4g.large"    = 0.625
    "db.t4g.medium"   = 0.625
    "db.t3.micro"     = 0.625
    "db.t3.small"     = 0.625
    "db.t3.medium"    = 0.625
    "db.t3.large"     = 0.625
    "db.t3.xlarge"    = 0.625
    "db.t3.2xlarge"   = 0.625
  }

}

resource "aws_cloudwatch_metric_alarm" "rds" {
  for_each = local.rds_alarms_map

  alarm_name          = "${var.rds_db}-${each.key}"
  comparison_operator = each.value["comparison_operator"]
  evaluation_periods  = 5
  metric_name         = each.value["metric_name"]
  threshold           = each.value["threshold"]
  alarm_description   = each.value["alarm_description"]
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  dimensions = {
    DBInstanceIdentifier = var.rds_db
  }
}
