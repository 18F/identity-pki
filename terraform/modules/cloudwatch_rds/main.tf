locals {
  rds_alarms_map = {
    highDiskQueueDepth = {
      comparison_operator = "GreaterThanThreshold"
      metric_name         = "DiskQueueDepth"
      threshold           = 20
      alarm_description   = "Average database disk queue depth is too high, performance may be negatively impacted."
    },
    lowFreeStorageSpace = {
      comparison_operator = "LessThanThreshold"
      metric_name         = "FreeStorageSpace"
      threshold           = var.rds_storage_threshold
      alarm_description   = "Average database free storage space is too low and may fill up soon."
    },
    readIOPStoohigh = {
      comparison_operator = "GreaterThanThreshold"
      metric_name         = "ReadIOPS"
      threshold           = 2500
      alarm_description   = "ReadIOPS is too high. Check RDS Instance and add more memory."
    },
    writeIOPStoohigh = {
      comparison_operator = "GreaterThanThreshold"
      metric_name         = "WriteIOPS"
      threshold           = 2500
      alarm_description   = "Write IOPS is too high. Check RDS Instance and review storage space."
    },
    MaximumUsedTransactionIDstoohigh = {
      comparison_operator = "GreaterThanThreshold"
      metric_name         = "MaximumUsedTransactionIDs"
      threshold           = var.unvacummed_transactions_count
      alarm_description   = "Usage of Transaction IDs in PostgreSQL Database is high. Check RDS Instance, review and cleanup the unvacuumed transactions before the autovacuum kicks in."
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
