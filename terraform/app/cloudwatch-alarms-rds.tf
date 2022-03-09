locals {
  rds_id = compact([aws_db_instance.idp.id, aws_db_instance.idp-worker-jobs.id,
    var.apps_enabled == 1 ? aws_db_instance.default[0].id : "",
    var.enable_rds_idp_read_replica == true ? aws_db_instance.idp-read-replica[0].id : ""]
  )
}
resource "aws_cloudwatch_metric_alarm" "disk_queue_depth_too_high" {
  for_each            = toset(local.rds_id)
  alarm_name          = "${each.value}-highDiskQueueDepth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  metric_name         = "DiskQueueDepth"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 20
  alarm_description   = "Average database disk queue depth is too high, performance may be negatively impacted."
  alarm_actions       = local.low_priority_alarm_actions
  ok_actions          = local.low_priority_alarm_actions

  dimensions = {
    DBInstanceIdentifier = each.value
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_free_storage_space_too_low" {
  for_each            = toset(local.rds_id)
  alarm_name          = "${each.value}-lowFreeStorageSpace"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 5
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = var.disk_free_storage_space_too_low_threshold
  alarm_description   = "Average database free storage space is too low and may fill up soon."
  alarm_actions       = local.low_priority_alarm_actions
  ok_actions          = local.low_priority_alarm_actions

  dimensions = {
    DBInstanceIdentifier = each.value
  }

}

resource "aws_cloudwatch_metric_alarm" "read_iops_too_high" {
  for_each            = toset(local.rds_id)
  alarm_name          = "${each.value}-readIOPStoohigh"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  metric_name         = "ReadIOPS"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 2500
  alarm_description   = "ReadIOPS is too high. Check RDS Instance and add more memory."
  alarm_actions       = local.low_priority_alarm_actions
  ok_actions          = local.low_priority_alarm_actions

  dimensions = {
    DBInstanceIdentifier = each.value
  }

}

resource "aws_cloudwatch_metric_alarm" "write_iops_too_high" {
  for_each            = toset(local.rds_id)
  alarm_name          = "${each.value}-writeIOPStoohigh"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  metric_name         = "WriteIOPS"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 2500
  alarm_description   = "Write IOPS is too high. Check RDS Instance and review storage space."
  alarm_actions       = local.low_priority_alarm_actions
  ok_actions          = local.low_priority_alarm_actions

  dimensions = {
    DBInstanceIdentifier = each.value
  }
}
