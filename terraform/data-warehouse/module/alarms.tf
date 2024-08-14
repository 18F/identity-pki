module "analytics_insufficent_instances_alerts" {
  source = "../../modules/asg_insufficent_instances_alerts"

  asg_name           = aws_autoscaling_group.analytics.name
  alarm_actions      = [var.slack_events_sns_hook_arn]
  treat_missing_data = var.cloudwatch_treat_missing_data
}

module "outboundproxy_insufficent_instances_alerts" {
  source = "../../modules/asg_insufficent_instances_alerts"

  asg_name           = module.outbound_proxy.proxy_asg_name
  alarm_actions      = [var.slack_events_sns_hook_arn]
  treat_missing_data = var.cloudwatch_treat_missing_data
}

module "analytics_resource_alerts" {
  source = "../../modules/asg_instance_low_resource_alerts"

  region             = var.region
  asg_name           = aws_autoscaling_group.analytics.name
  env_name           = var.env_name
  alarm_actions      = [var.slack_events_sns_hook_arn]
  treat_missing_data = var.cloudwatch_treat_missing_data
}

