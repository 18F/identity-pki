# IdP specific alarms
module "elb_http_alerts" {
  source = "github.com/18F/identity-terraform//elb_http_alerts?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/elb_http_alerts"

  env_name = var.env_name
  lb_name  = aws_alb.idp.name
  lb_type  = "ALB"

  // These are defined in variables.tf
  alarm_actions = local.high_priority_alarm_actions
}

module "idp_insufficent_instances_alerts" {
  source = "../modules/asg_insufficent_instances_alerts"

  asg_name = aws_autoscaling_group.idp.name

  alarm_actions = local.high_priority_alarm_actions
}

module "idp_unhealthy_instances_alerts" {
  source = "../modules/alb_unhealthy_instances_alerts"

  asg_name                = aws_autoscaling_group.idp.name
  alb_arn_suffix          = aws_alb.idp.arn_suffix
  target_group_arn_suffix = aws_alb_target_group.idp-ssl.arn_suffix

  alarm_actions = local.low_priority_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "low_proofing_activity" {
  count = var.proofing_low_alert_threshold > 0 ? 1 : 0

  alarm_name        = "${var.env_name}-low_proofing_activity"
  alarm_description = <<EOM
${var.env_name}: Less than ${var.proofing_low_alert_threshold} users have completed ID verifcation in the last hour
See https://github.com/18F/identity-devops/wiki/Runbook:-Low-User-Activity#low_proofing_activity
EOM

  namespace = "${var.env_name}/idp-ialx"

  metric_name = "idv-review-complete-success"

  statistic           = "Sum"
  comparison_operator = "LessThanThreshold"
  threshold           = var.proofing_low_alert_threshold
  period              = 3600
  evaluation_periods  = 1

  treat_missing_data = "breaching"

  alarm_actions = local.low_priority_alarm_actions
  ok_actions    = local.low_priority_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "low_sms_mfa_activity" {
  count = var.sms_mfa_low_alert_threshold > 0 ? 1 : 0

  alarm_name        = "${var.env_name}-low_sms_mfa_activity"
  alarm_description = <<EOM
${var.env_name}: Less than ${var.sms_mfa_low_alert_threshold} users have authenticated with SMS in 10 minutes
See https://github.com/18F/identity-devops/wiki/Runbook:-Low-User-Activity#low_sms_mfa_activity
EOM

  namespace = "${var.env_name}/idp-authentication"

  metric_name = "login-mfa-success"

  dimensions = {
    multi_factor_auth_method = "sms"
  }

  statistic           = "Sum"
  comparison_operator = "LessThanThreshold"
  threshold           = var.sms_mfa_low_alert_threshold
  period              = 600
  evaluation_periods  = 1

  treat_missing_data = "breaching"

  alarm_actions = local.low_priority_alarm_actions
  ok_actions    = local.low_priority_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "low_sms_mfa_success" {
  count             = var.sms_mfa_low_success_alert_threshold > 0 ? 1 : 0
  alarm_name        = "${var.env_name}-low_sms_mfa_success"
  alarm_description = <<EOM
${var.env_name}: SMS MFA confirmation success rate less than ${var.sms_mfa_low_success_alert_threshold}% in 10 minutes
See https://github.com/18F/identity-devops/wiki/Runbook:-Pinpoint-SMS-and-Voice#sms-delivery
EOM

  metric_query {
    id          = "success_rate"
    expression  = "(successes / (successes + failures)) * 100"
    label       = "Success Rate"
    return_data = "true"
  }

  metric_query {
    id = "failures"

    metric {
      metric_name = "login-mfa-failure"
      namespace   = "${var.env_name}/idp-authentication"
      period      = 600
      stat        = "Sum"

      dimensions = {
        multi_factor_auth_method = "sms"
      }
    }
  }

  metric_query {
    id = "successes"

    metric {
      metric_name = "login-mfa-success"
      namespace   = "${var.env_name}/idp-authentication"
      period      = 600
      stat        = "Sum"

      dimensions = {
        multi_factor_auth_method = "sms"
      }
    }
  }

  comparison_operator = "LessThanThreshold"
  threshold           = var.sms_mfa_low_success_alert_threshold
  evaluation_periods  = 1

  treat_missing_data = "breaching"

  alarm_actions = local.low_priority_alarm_actions
  ok_actions    = local.low_priority_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "low_sp_return_activity" {
  count = var.sp_return_low_alert_threshold > 0 ? 1 : 0

  alarm_name        = "${var.env_name}-low_sp_return_activity"
  alarm_description = <<EOM
${var.env_name}: Less than ${var.sp_return_low_alert_threshold} users have been returned to an SP in 10 minutes
See https://github.com/18F/identity-devops/wiki/Runbook:-Low-User-Activity#low_sp_return_activity
EOM

  namespace = "${var.env_name}/idp-authentication"

  metric_name = "sp-redirect-initiated-all"

  statistic           = "Sum"
  comparison_operator = "LessThanThreshold"
  threshold           = var.sp_return_low_alert_threshold
  period              = 600
  evaluation_periods  = 1

  treat_missing_data = "breaching"

  # This should be a fairly high fidelity sign that people are not having a good time
  alarm_actions = local.high_priority_alarm_actions
  ok_actions    = local.high_priority_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "low_user_registration_activity" {
  count = var.user_registration_low_alert_threshold > 0 ? 1 : 0

  alarm_name        = "${var.env_name}-low_user_registration_activity"
  alarm_description = <<EOM
${var.env_name}: Less than ${var.user_registration_low_alert_threshold} users have created new accounts in the last 10 minutes.
See https://github.com/18F/identity-devops/wiki/Runbook:-Low-User-Activity#low_user_registration_activity
EOM

  namespace = "${var.env_name}/idp-authentication"

  metric_name = "user-registration-complete"

  statistic           = "Sum"
  comparison_operator = "LessThanThreshold"
  threshold           = var.user_registration_low_alert_threshold
  period              = 600
  evaluation_periods  = 1

  treat_missing_data = "breaching"

  # This should be a fairly high fidelity sign that people are not having a good time
  alarm_actions = local.high_priority_alarm_actions
  ok_actions    = local.high_priority_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "idp_too_many_healthy_instances_alert" {
  alarm_name        = "${aws_autoscaling_group.idp.name}-healthy-instances"
  alarm_description = "${aws_autoscaling_group.idp.name}: Too many healthy instances"
  namespace         = "AWS/ApplicationELB"

  metric_name = "HealthyHostCount"
  dimensions = {
    LoadBalancer = aws_alb.idp.arn_suffix
    TargetGroup  = aws_alb_target_group.idp-ssl.arn_suffix
  }

  statistic           = "Maximum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.asg_idp_desired
  period              = 300
  evaluation_periods  = 12

  treat_missing_data = "notBreaching"

  alarm_actions = local.low_priority_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "worker_too_many_healthy_instances_alert" {
  alarm_name        = "${aws_autoscaling_group.worker.name}-healthy-instances"
  alarm_description = "${aws_autoscaling_group.worker.name}: Too many healthy instances"
  namespace         = "AWS/ApplicationELB"

  metric_name = "HealthyHostCount"
  dimensions = {
    LoadBalancer = aws_alb.worker.arn_suffix
    TargetGroup  = aws_alb_target_group.worker_ssl.arn_suffix
  }

  statistic           = "Maximum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.asg_worker_desired
  period              = 300
  evaluation_periods  = 12

  treat_missing_data = "notBreaching"

  alarm_actions = local.low_priority_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "pii_spill_detector_alarm" {
  alarm_name                = "${var.env_name}-pii-spill-detector-alarm"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  metric_name               = "PII_Spill_Event"
  namespace                 = "${var.env_name}/SpillDetectorMetrics"
  period                    = "900"
  statistic                 = "Sum"
  threshold                 = "0"
  treat_missing_data        = "notBreaching"
  insufficient_data_actions = []
  alarm_actions             = local.high_priority_alarm_actions
  alarm_description         = <<EOM
${var.env_name}: PII Spill Detector Alarm - Sample PII may be present in event.log
See https://github.com/18F/identity-devops/wiki/Runbook:-PII-spilled-into-logs#pii_spill_event-alert
EOM
}

resource "aws_cloudwatch_metric_alarm" "in-person-proofing-enrollment-alarm" {
  alarm_name                = "${var.env_name}-in-person-proofing-failure"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  metric_name               = "login-in-person-proofing-failure"
  namespace                 = "${var.env_name}/idp-in-person-proofing"
  period                    = "300"
  statistic                 = "Sum"
  threshold                 = "0"
  treat_missing_data        = "notBreaching"
  insufficient_data_actions = []
  alarm_actions             = local.in_person_alarm_actions
  alarm_description         = <<EOM
${var.env_name}: Alarm tracking In Person Proofing Enrollment Requests Failure
See https://github.com/18F/identity-devops/wiki/Runbook:-In-Person-Proofing-Alarms
EOM
}

resource "aws_cloudwatch_metric_alarm" "attempts-api-event-auth-alarm" {
  alarm_name                = "${var.env_name}-attempts-api-event-auth-failure"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  metric_name               = "attempts-api-events-auth-failure"
  namespace                 = "${var.env_name}/attempts-api-events"
  period                    = "300"
  statistic                 = "Sum"
  threshold                 = "0"
  treat_missing_data        = "notBreaching"
  insufficient_data_actions = []
  alarm_actions             = local.low_priority_alarm_actions
  alarm_description         = <<EOM
${var.env_name}: IRS Attempts API authentication failure(s) detected.
See https://github.com/18F/identity-devops/wiki/Runbook:-IRS-Attempts-API-Event---Authentication-Failure
EOM
}

resource "aws_cloudwatch_metric_alarm" "attempts-api-low-success-rate-alarm" {
  count               = var.attempts_api_low_success_alarm_threshold > 0 ? 1 : 0
  alarm_name          = "${var.env_name}-attempts-api-low-success-rate"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "attempts-api-events-success"
  namespace           = "${var.env_name}/attempts-api-events"
  period              = "5400"
  statistic           = "Sum"
  threshold           = var.attempts_api_low_success_alarm_threshold
  treat_missing_data  = "breaching"
  alarm_actions       = local.low_priority_alarm_actions
  alarm_description   = <<EOM
${var.env_name}: IRS Attempts API - Less than ${var.attempts_api_low_success_alarm_threshold} successful call in the last 90 minutes. 
See https://github.com/18F/identity-devops/wiki/Runbook:-IRS-Attempts-API-Event---Low-Success-Rate
EOM
}

resource "aws_cloudwatch_metric_alarm" "usps_proofing_exception_alarm" {
  alarm_name                = "${var.env_name}-GetUspsProofingResultsJob-exception"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  metric_name               = "usps-proofing-unexpected-exception"
  namespace                 = "${var.env_name}/idp-in-person-proofing"
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "0"
  alarm_description         = <<EOM
This alarm is executed when an exception is thrown

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-In-Person-Proofing-Alarms
EOM
  treat_missing_data        = "missing"
  insufficient_data_actions = []
  alarm_actions             = local.in_person_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "low-sp-oidc-token-success" {
  for_each            = var.low_sp_oidc_token_enabled_sps
  alarm_name          = "${var.env_name}-${each.key}-low-sp-oidc-token-success"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "sp-oidc-token-success"
  namespace           = "${var.env_name}/idp-authentication"
  dimensions = {
    service_provider = "${each.value.client_id}"
  }
  period             = "300"
  statistic          = "Sum"
  threshold          = each.value.threshold
  treat_missing_data = "breaching"
  alarm_actions      = local.high_priority_alarm_actions
  alarm_description  = <<EOM
${var.env_name}: Low OpenID Connect Token success - ${each.value.sp_name} (${each.value.client_id})

Less than ${each.value.threshold} successful server to server calls to /api/openid_connect/token in the last 5 minutes. 
See https://github.com/18F/identity-devops/wiki/Runbook:-OIDC-Connect-Token-Low-Success-Rate
EOM
}
