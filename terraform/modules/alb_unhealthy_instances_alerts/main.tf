variable "asg_name" {
  description = "Autoscaling Group name"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Target group ARN suffix"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ALB/NLB ARN suffix"
  type        = string
}

variable "alarm_actions" {
  type        = list(string)
  description = "A list of ARNs to notify when the alarms fire"
}

resource "aws_cloudwatch_metric_alarm" "unhealthy-instances-alb" {
  # Named by ASG even though we get the info through LB metrics
  alarm_name        = "${var.asg_name}-unhealthy-instances"
  alarm_description = "${var.asg_name}: Previously healthy instances have fallen ill"
  namespace         = "AWS/ApplicationELB"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix,
    TargetGroup  = var.target_group_arn_suffix
  }

  statistic           = "Max"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  period              = 900
  evaluation_periods  = 1

  treat_missing_data = "notBreaching"

  alarm_actions = var.alarm_actions
  ok_actions    = var.alarm_actions
}

