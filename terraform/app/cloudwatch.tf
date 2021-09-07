# cloudwatch dashboard for IDP
module "idp_dashboard" {
  source = "github.com/18F/identity-terraform//cloudwatch_dashboard_alb?ref=b68c41068a53acbb981eeb37e1eb0a36a6487ac7"

  dashboard_name          = "${var.env_name}-idp"
  alb_arn_suffix          = aws_alb.idp.arn_suffix
  target_group_label      = "${var.env_name} IDP"
  target_group_arn_suffix = aws_alb_target_group.idp-ssl.arn_suffix
  asg_name                = aws_autoscaling_group.idp.name

  # annotations of when some major partner launches happened
  vertical_annotations = <<EOM
[
  {
    "color": "#666",
    "label": "CBP TTP Launch",
    "value": "2017-10-01T16:00:00.000Z"
  },
  {
    "color": "#666",
    "label": "USAJobs Launch",
    "value": "2018-02-25T15:00:00.000Z"
  }
]
EOM

}

output "idp_dashboard_arn" {
  value = module.idp_dashboard.dashboard_arn
}

module "rds_dashboard_idp" {
  source = "github.com/18F/identity-terraform//cloudwatch_dashboard_rds?ref=b68c41068a53acbb981eeb37e1eb0a36a6487ac7"

  dashboard_name = "${var.env_name}-RDS-idp"

  region = var.region

  db_instance_identifier = aws_db_instance.idp.id
  iops                   = var.rds_iops_idp

  vertical_annotations = var.rds_dashboard_idp_vertical_annotations
}

module "elb_http_alerts" {
  source = "github.com/18F/identity-terraform//elb_http_alerts?ref=b68c41068a53acbb981eeb37e1eb0a36a6487ac7"

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

resource "aws_cloudwatch_metric_alarm" "idv_final_resolution_success_minimum" {
  count = var.idv_final_resolution_success_minimum_threshold > 0 ? 1 : 0

  alarm_name        = "${var.env_name}-idv_final_resolution_success_minimum"
  alarm_description = "${var.env_name}: Less than ${var.idv_final_resolution_success_minimum_threshold} users have completed IDV in the last hour"
  namespace         = "${var.env_name}/idp-ialx"

  metric_name = "idv-final-resolution-success"

  statistic           = "Sum"
  comparison_operator = "LessThanThreshold"
  threshold           = var.idv_final_resolution_success_minimum_threshold
  period              = 3600
  evaluation_periods  = 1

  treat_missing_data = "breaching"

  alarm_actions = local.low_priority_alarm_actions
  ok_actions    = local.low_priority_alarm_actions
}

