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

variable "treat_missing_data" {
  type    = string
  default = "missing"
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
${var.alert_handle} An instance in ASG ${var.asg_name} has exceeded ${var.high_mem_threshold}% memory utilization for over 60 seconds. This is a critical alert. Dashboard: https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${var.asg_name}-instance-resource-use Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-High-Memory-and-Disk-Usage
EOM
  alarm_actions       = var.alarm_actions
  treat_missing_data  = var.treat_missing_data

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
${var.alert_handle} An instance in ASG ${var.asg_name} has exceeded ${var.high_disk_threshold}% disk space utilization for over 60 seconds. This is a critical alert. Dashboard: https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${var.asg_name}-instance-resource-use Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-High-Memory-and-Disk-Usage
EOM
  alarm_actions       = var.alarm_actions
  treat_missing_data  = var.treat_missing_data

  dimensions = {
    AutoScalingGroupName = var.asg_name
    path                 = each.key
  }
}

resource "aws_cloudwatch_dashboard" "instance_resource_use" {
  dashboard_name = "${var.asg_name}-instance-resource-use"
  dashboard_body = <<EOF
{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 10,
            "height": 14,
            "properties": {
                "metrics": [
                    [ { "expression": "SEARCH('{${var.env_name}/EC2,AutoScalingGroupName,InstanceId,InstanceType,fstype,path} AutoScalingGroupName=\"${var.asg_name}\" MetricName=\"disk_used_percent\"', 'Average', 60)", "label": "", "id": "q1" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "stat": "Average",
                "period": 300,
                "start": "-PT72H",
                "end": "P0D",
                "title": "Percentage of disk space used",
                "yAxis": {
                    "left": {
                        "showUnits": false
                    }
                }
            }
        },
        {
            "type": "metric",
            "x": 10,
            "y": 0,
            "width": 10,
            "height": 14,
            "properties": {
                "metrics": [
                    [ { "expression": "SEARCH('{${var.env_name}/EC2,AutoScalingGroupName,InstanceId,InstanceType} AutoScalingGroupName=\"${var.asg_name}\" MetricName=\"mem_used_percent\"', 'Average', 300)", "id": "e2", "period": 300, "region": "us-west-2" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "stat": "Average",
                "period": 300,
                "title": "Percentage of memory used",
                "yAxis": {
                    "left": {
                        "showUnits": false
                    }
                }
            }
        }
    ]
}
EOF
}
