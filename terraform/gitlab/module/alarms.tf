module "gitlab_insufficent_instances_alerts" {
  source = "../../modules/asg_insufficent_instances_alerts"

  asg_name = aws_autoscaling_group.gitlab.name

  alarm_actions = [var.slack_events_sns_hook_arn]
}

module "gitlab_outboundproxy_insufficent_instances_alerts" {
  source = "../../modules/asg_insufficent_instances_alerts"

  asg_name = module.outbound_proxy.proxy_asg_name

  alarm_actions = [var.slack_events_sns_hook_arn]
}

module "gitlab_build_pool_insufficent_instances_alerts" {
  source = "../../modules/asg_insufficent_instances_alerts"

  asg_name = module.build_pool.runner_asg_name

  alarm_actions = [var.slack_events_sns_hook_arn]
}

module "gitlab_test_pool_insufficent_instances_alerts" {
  source = "../../modules/asg_insufficent_instances_alerts"

  asg_name = module.test_pool.runner_asg_name

  alarm_actions = [var.slack_events_sns_hook_arn]
}

module "gitlab_deploy_pool_insufficent_instances_alerts" {
  source = "../../modules/asg_insufficent_instances_alerts"

  asg_name = module.deploy_pool.runner_asg_name

  alarm_actions = [var.slack_events_sns_hook_arn]
}

module "newrelic" {
  source = "../../modules/newrelic/"

  enabled        = 1
  gitlab_enabled = 1
  region         = var.region
  env_name       = var.env_name
  root_domain    = var.root_domain
}
