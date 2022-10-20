locals {
  all_asg_names = compact([
    aws_autoscaling_group.idp.name,
    aws_autoscaling_group.jumphost.name,
    aws_autoscaling_group.migration.name,
    aws_autoscaling_group.pivcac.name,
    aws_autoscaling_group.outboundproxy.name,
    aws_autoscaling_group.worker.name,
    var.apps_enabled == 1 ? aws_autoscaling_group.app[0].name : "",
    var.enable_loadtesting ? aws_autoscaling_group.locust_leader[0].name : "",
    var.enable_loadtesting ? aws_autoscaling_group.locust_worker[0].name : "",
    var.gitlab_runner_enabled ? module.env-runner[0].runner_asg_name : "",
  ])
}

resource "aws_cloudwatch_event_rule" "asg_refresh" {
  name          = "${var.env_name}-asg-refresh"
  description   = "Cancelled/failed ASG instance refreshes in ${var.env_name} environment"
  event_pattern = <<EOF
  {
    "source": ["aws.autoscaling"],
    "detail-type": [
      "EC2 Auto Scaling Instance Refresh Cancelled",
      "EC2 Auto Scaling Instance Refresh Failed"
    ],
    "detail": {
      "AutoScalingGroupName": ${jsonencode(local.all_asg_names)}
    }
  }
  EOF
}

resource "aws_cloudwatch_event_target" "asg_refresh" {
  rule      = aws_cloudwatch_event_rule.asg_refresh.name
  target_id = "SendInstanceRefreshEventsToSlackViaSNS"
  arn       = var.slack_events_sns_hook_arn

  input_transformer {
    input_paths = {
      refresh_id    = "$.detail.InstanceRefreshId",
      asg           = "$.detail.AutoScalingGroupName",
      region        = "$.region",
      time_of_issue = "$.time",
      detail        = "$.detail-type",
    }
    input_template = "\"ASG <asg> <detail> Region: <region> Time: <time_of_issue> ID:<refresh_id>\""
  }
}
