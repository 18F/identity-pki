variable "asg_name" {
  description = "Autoscaling Group name"
  type        = string
}

variable "alarm_actions" {
  type        = list(string)
  description = "A list of ARNs to notify when the alarms fire"
}

resource "aws_cloudwatch_metric_alarm" "insufficient-instances" {
  alarm_name        = "${var.asg_name}-insufficient-instances"
  alarm_description = "The number of healthy instances has fallen two or more instances under the minimum number for the autoscaling group"

  # Using derived metric to allow setting min manually if needed
  metric_query {
    id = "e1"
    # Mininum Instances - Healthy Instances = Deficit
    expression = "m1-m2"
    label      = "Healthy Instance Deficit"
    # Use this as the metric to alarm on
    return_data = "true"
  }

  metric_query {
    id = "m1"
    metric {
      namespace   = "AWS/AutoScaling"
      metric_name = "GroupMinSize"
      period      = "60"
      stat        = "Minimum"
      dimensions = {
        AutoScalingGroupName = var.asg_name
      }
    }
  }

  metric_query {
    id = "m2"
    metric {
      namespace   = "AWS/AutoScaling"
      metric_name = "GroupInServiceInstances"
      period      = "60"
      stat        = "Minimum"
      dimensions = {
        AutoScalingGroupName = var.asg_name
      }
    }
  }

  comparison_operator = "GreaterThanThreshold"
  # Allow a dip of one under minimum
  threshold           = 1
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = var.alarm_actions
  ok_actions    = var.alarm_actions
}
