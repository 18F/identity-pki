variable "env_name" {
  type = string
}

variable "asg_name" {
  type = string
}

variable "high_mem_threshold" {
  type        = number
  description = "Critical memory used percentage threshold. Above 80, the AWS agent may not reliably send data."
  default     = 75
}

variable "high_disk_threshold" {
  type    = number
  default = 75
}

variable "paths" {
  type    = list(string)
  default = ["/", "/var"]
}

variable "region" {
  type = string
}

variable "alert_handle" {
  type    = string
  default = ""
}

variable "alarm_actions" {
  type = list(string)
}


# High memory usage. Excludes OS cache and buffers.
resource "aws_cloudwatch_metric_alarm" "memory_used" {
  alarm_name          = "${var.asg_name}-Memory-Critical"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "mem_used_percent"
  namespace           = "${var.env_name}/EC2"
  period              = 60
  threshold           = var.high_mem_threshold
  statistic           = "Maximum"
  alarm_description   = <<EOM
${var.alert_handle} An instance in ASG ${var.asg_name} has exceeded ${var.high_mem_threshold}% memory utilization for over 60 seconds. This is a critical alert.
EOM
  alarm_actions       = var.alarm_actions

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }
}

# Low disk space
resource "aws_cloudwatch_metric_alarm" "disk_used" {
  for_each            = toset(var.paths)
  alarm_name          = "${var.asg_name}-${each.key}-Disk-Critical"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "disk_used_percent"
  namespace           = "${var.env_name}/EC2"
  period              = 60
  threshold           = var.high_disk_threshold
  statistic           = "Maximum"
  alarm_description   = <<EOM
${var.alert_handle} An instance in ASG ${var.asg_name} has exceeded ${var.high_disk_threshold}% disk space utilization for over 60 seconds. This is a critical alert.
EOM
  alarm_actions       = var.alarm_actions

  dimensions = {
    AutoScalingGroupName = var.asg_name
    path                 = each.key
  }
}
