# IdP specific alarms
module "elb_http_alerts" {
  source = "github.com/18F/identity-terraform//elb_http_alerts?ref=7e11ebe24e3a9cbc34d1413cf4d20b3d71390d5b"

  env_name         = var.env_name
  load_balancer_id = aws_alb.idp.id

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

resource "aws_cloudwatch_metric_alarm" "sp_redirect_initiated_minimum" {
  count = var.sp_redirect_initiated_minimum_threshold > 0 ? 1 : 0

  alarm_name        = "${var.env_name}-sp_redirect_initiated_minimum"
  alarm_description = "${var.env_name}: Less than ${var.sp_redirect_initiated_minimum_threshold} users have been returned to an SP in 10 minutes"
  namespace         = "${var.env_name}/idp-authentication"

  metric_name = "sp-redirect-initiated-all"

  statistic           = "Sum"
  comparison_operator = "LessThanThreshold"
  threshold           = var.sp_redirect_initiated_minimum_threshold
  period              = 600
  evaluation_periods  = 1

  treat_missing_data = "breaching"

  # This should be a fairly high fidelity sign that people are not having a good time
  alarm_actions = local.high_priority_alarm_actions
  ok_actions    = local.high_priority_alarm_actions
}

# TODO - MORE!
# sign in
# sign up
# sms login?

resource "aws_cloudwatch_metric_alarm" "idv_review_complete_success_minimum" {
  count = var.idv_review_complete_success_minimum_threshold > 0 ? 1 : 0

  alarm_name        = "${var.env_name}-idv_review_complete_success_minimum"
  alarm_description = "${var.env_name}: Less than ${var.idv_review_complete_success_minimum_threshold} users have completed IDV in the last hour"
  namespace         = "${var.env_name}/idp-ialx"

  metric_name = "idv-review-complete-success"

  statistic           = "Sum"
  comparison_operator = "LessThanThreshold"
  threshold           = var.idv_review_complete_success_minimum_threshold
  period              = 3600
  evaluation_periods  = 1

  treat_missing_data = "breaching"

  alarm_actions = local.low_priority_alarm_actions
  ok_actions    = local.low_priority_alarm_actions
}

