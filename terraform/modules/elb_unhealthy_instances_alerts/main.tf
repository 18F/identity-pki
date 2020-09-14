variable "asg_name" {
  description = "Autoscaling Group name"
  type        = string
}

variable "elb_name" {
  description = "ELB name"
  type        = string
}

variable "alarm_actions" {
  type        = list(string)
  description = "A list of ARNs to notify when the alarms fire"
}

resource "aws_cloudwatch_metric_alarm" "unhealthy-instances-elb" {
  # Named by ASG even though we get the info through LB metrics
  alarm_name        = "${var.asg_name}-unhealthy-instances"
  alarm_description = "${var.asg_name}: Previously healthy instances have fallen ill"
  namespace         = "AWS/ELB"

  metric_name = "UnHealthyHostCount"
  dimensions = {
    LoadBalancerName = var.elb_name
  }

  statistic           = "Maximum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  period              = 300
  evaluation_periods  = 1

  treat_missing_data = "notBreaching"

  alarm_actions = var.alarm_actions
  ok_actions    = var.alarm_actions
}
