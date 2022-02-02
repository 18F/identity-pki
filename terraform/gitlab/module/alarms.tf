module "gitlab_insufficent_instances_alerts" {
  source = "../../modules/asg_insufficent_instances_alerts"

  asg_name = module.gitlab_build_runner_pool.runner_asg_name

  alarm_actions = [var.slack_events_sns_hook_arn]
}

module "gitlab_runner_insufficent_instances_alerts" {
  source = "../../modules/asg_insufficent_instances_alerts"

  asg_name = module.gitlab_build_runner_pool.runner_asg_name

  alarm_actions = [var.slack_events_sns_hook_arn]
}
