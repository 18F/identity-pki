module "gitlab_insufficent_instances_alerts" {
  source = "../../modules/asg_insufficent_instances_alerts"

  asg_name           = aws_autoscaling_group.gitlab.name
  alarm_actions      = [var.slack_events_sns_hook_arn]
  treat_missing_data = var.cloudwatch_treat_missing_data
}

module "gitlab_outboundproxy_insufficent_instances_alerts" {
  source = "../../modules/asg_insufficent_instances_alerts"

  asg_name           = module.outbound_proxy.proxy_asg_name
  alarm_actions      = [var.slack_events_sns_hook_arn]
  treat_missing_data = var.cloudwatch_treat_missing_data
}

module "gitlab_build_pool_insufficent_instances_alerts" {
  source = "../../modules/asg_insufficent_instances_alerts"

  asg_name           = module.build_pool.runner_asg_name
  alarm_actions      = [var.slack_events_sns_hook_arn]
  treat_missing_data = var.cloudwatch_treat_missing_data
}

module "gitlab_test_pool_insufficent_instances_alerts" {
  source = "../../modules/asg_insufficent_instances_alerts"

  asg_name           = module.test_pool.runner_asg_name
  alarm_actions      = [var.slack_events_sns_hook_arn]
  treat_missing_data = var.cloudwatch_treat_missing_data
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
  treat_missing_data  = var.cloudwatch_treat_missing_data

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

  enabled              = 1
  gitlab_enabled       = 1
  region               = var.region
  env_name             = var.env_name
  root_domain          = var.root_domain
  pager_alerts_enabled = var.newrelic_pager_alerts_enabled
}

locals {
  alert_handle = var.env_type == "tooling-prod" ? "@login-devtools-oncall " : ""
}

module "gitlab_test_pool_resource_alerts" {
  source = "../../modules/asg_instance_low_resource_alerts"

  region             = var.region
  asg_name           = module.test_pool.runner_asg_name
  env_name           = var.env_name
  alert_handle       = local.alert_handle
  alarm_actions      = [var.slack_events_sns_hook_arn]
  treat_missing_data = var.cloudwatch_treat_missing_data
}

module "gitlab_build_pool_resource_alerts" {
  source = "../../modules/asg_instance_low_resource_alerts"

  region             = var.region
  asg_name           = module.build_pool.runner_asg_name
  env_name           = var.env_name
  alert_handle       = local.alert_handle
  alarm_actions      = [var.slack_events_sns_hook_arn]
  treat_missing_data = var.cloudwatch_treat_missing_data
}

module "gitlab_web_asg_resource_alerts" {
  source = "../../modules/asg_instance_low_resource_alerts"

  region             = var.region
  asg_name           = aws_autoscaling_group.gitlab.name
  env_name           = var.env_name
  alert_handle       = local.alert_handle
  alarm_actions      = [var.slack_events_sns_hook_arn]
  treat_missing_data = var.cloudwatch_treat_missing_data
}

locals {
  projects = yamldecode(file("${path.module}/../../master/global/users.yaml")).projects
}

resource "aws_cloudwatch_metric_alarm" "queue_depth" {
  for_each = local.projects

  actions_enabled     = true
  alarm_actions       = [var.slack_events_sns_hook_arn]
  alarm_description   = "${local.alert_handle}Alarms when there are too many pending Gitlab CI/CD jobs. Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-Gitlab-CI-Troubleshooting"
  alarm_name          = "GitLab-${var.env_name}-${each.key}-Job-Queue-Depth"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "pending-jobs"
  namespace           = "Gitlab/${var.env_name}"
  period              = 60
  statistic           = "Sum"
  threshold           = var.job_queue_depth_alert_threshold

  dimensions = {
    projectname = each.key
  }
}
