# PIVCAC
module "pivcac_elb_http_alerts" {
  source = "github.com/18F/identity-terraform//elb_http_alerts?ref=a6261020a94b77b08eedf92a068832f21723f7a2"

  env_name         = var.env_name
  load_balancer_id = aws_elb.pivcac.id

  // These are defined in variables.tf
  alarm_actions = local.high_priority_alarm_actions
}

module "pivcac_insufficent_instances_alerts" {
  source = "../modules/asg_insufficent_instances_alerts"

  asg_name = "${var.env_name}-pivcac"

  alarm_actions = local.high_priority_alarm_actions
}

module "pivcac_unhealthy_instances_alerts" {
  source = "../modules/elb_unhealthy_instances_alerts"

  asg_name = "${var.env_name}-pivcac"
  elb_name = "${var.env_name}-pivcac"

  alarm_actions = local.low_priority_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "low_pivcac_mfa_activity" {
  count = var.pivcac_mfa_low_alert_threshold > 0 ? 1 : 0

  alarm_name        = "${var.env_name}-low_pivcac_mfa_activity"
  alarm_description = <<EOM
${var.env_name}: Less than ${var.pivcac_mfa_low_alert_threshold} users have authenticated with PIV or CAC in 60 minutes
See https://github.com/18F/identity-devops/wiki/Runbook:-Low-User-Activity#low_pivcac_mfa_activity
EOM

  namespace = "${var.env_name}/idp-authentication"

  metric_name = "login-mfa-success"

  dimensions = {
    multi_factor_auth_method = "pivcac"
  }

  statistic           = "Sum"
  comparison_operator = "LessThanThreshold"
  threshold           = var.pivcac_mfa_low_alert_threshold
  period              = 3600
  evaluation_periods  = 1

  treat_missing_data = "breaching"

  alarm_actions = local.low_priority_alarm_actions
  ok_actions    = local.low_priority_alarm_actions
}

