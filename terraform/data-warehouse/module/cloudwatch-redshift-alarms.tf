locals {
  redshift_alarms_map = {
    HighCpuUtilization = {
      comparison_operator = "GreaterThanThreshold"
      metric_name         = "CPUUtilization"
      threshold           = var.redshift_alarm_threshold_cpu_high
      alarm_description   = <<EOM
CPUUtilization
EOM
    },
    CriticalCpuUtilization = {
      comparison_operator = "GreaterThanThreshold"
      metric_name         = "CPUUtilization"
      threshold           = var.redshift_alarm_threshold_cpu_critical
      alarm_description   = <<EOM
CPUUtilization
EOM
    },
    UnhealthyCluster = {
      comparison_operator = "LessThanThreshold"
      metric_name         = "HealthStatus"
      threshold           = 1
      alarm_description   = <<EOM
UnhealthyCluster
EOM
    },
    HighDiskSpaceUsed = {
      comparison_operator = "GreaterThanThreshold"
      metric_name         = "PercentageDiskSpaceUsed"
      threshold           = var.redshift_alarm_threshold_diskspace_high
      alarm_description   = <<EOM
HighDiskSpaceUsed
EOM
    },
    CriticalDiskSpaceUsed = {
      comparison_operator = "GreaterThanThreshold"
      metric_name         = "PercentageDiskSpaceUsed"
      threshold           = var.redshift_alarm_threshold_diskspace_critical
      alarm_description   = <<EOM
CriticalDiskSpaceUsed
EOM
    },
  }


}

resource "aws_cloudwatch_metric_alarm" "redshift" {
  for_each = local.redshift_alarms_map

  alarm_name          = "${aws_redshift_cluster.redshift.id}-redshift-${each.key}"
  comparison_operator = each.value["comparison_operator"]
  evaluation_periods  = lookup(each.value, "evaluation_periods", 5)
  metric_name         = each.value["metric_name"]
  threshold           = each.value["threshold"]
  alarm_description   = each.value["alarm_description"]
  namespace           = "AWS/Redshift"
  period              = lookup(each.value, "period", 60)
  statistic           = "Average"
  alarm_actions       = local.moderate_priority_alarm_actions
  ok_actions          = local.moderate_priority_alarm_actions

  dimensions = {
    ClusterIdentifier = aws_redshift_cluster.redshift.id
  }
}
