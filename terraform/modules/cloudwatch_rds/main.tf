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
