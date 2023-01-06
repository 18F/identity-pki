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

resource "aws_cloudwatch_metric_alarm" "generic_alarm" {
  actions_enabled     = true
  alarm_actions       = [var.slack_events_sns_hook_arn]
  alarm_description   = "Alarms when LB targets are unhealthy"
  alarm_name          = "GitLab-${var.env_name}-LoadBalancer-Unhealthy"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/NetworkELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 1

  dimensions = {
    TargetGroup  = aws_lb_target_group.gitlab.arn_suffix
    LoadBalancer = aws_lb.gitlab.arn_suffix
  }
}

data "aws_s3_object" "newrelic_apikey" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "common/newrelic_apikey"
}

data "aws_s3_object" "newrelic_account_id" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "common/newrelic_account_id"
}

provider "newrelic" {
  region     = "US"
  account_id = data.aws_s3_object.newrelic_account_id.body
  api_key    = data.aws_s3_object.newrelic_apikey.body
}

module "newrelic" {
  source = "../../modules/newrelic/"

  enabled        = 1
  gitlab_enabled = 1
  region         = var.region
  env_name       = var.env_name
  root_domain    = var.root_domain
}