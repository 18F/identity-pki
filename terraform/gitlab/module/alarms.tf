module "gitlab_insufficent_instances_alerts" {
  source = "../../modules/asg_insufficent_instances_alerts"

  asg_name = aws_autoscaling_group.gitlab.name

  alarm_actions = [var.slack_events_sns_hook_arn]
}

module "gitlab_runner_insufficent_instances_alerts" {
  source = "../../modules/asg_insufficent_instances_alerts"

  asg_name = aws_autoscaling_group.gitlab_runner.name

  alarm_actions = [var.slack_events_sns_hook_arn]
}
