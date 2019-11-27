# cloudwatch dashboard for IDP
module "idp_dashboard" {
  source = "github.com/18F/identity-terraform//cloudwatch_dashboard_alb?ref=a383cf2dc02036029e966e3401fbbe07e77f7186"

  enabled = var.alb_enabled

  dashboard_name          = "${var.env_name}-idp"
  alb_arn_suffix          = aws_alb.idp[0].arn_suffix
  target_group_label      = "${var.env_name} IDP"
  target_group_arn_suffix = aws_alb_target_group.idp-ssl[0].arn_suffix
  asg_name                = aws_autoscaling_group.idp[0].name

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
  source = "github.com/18F/identity-terraform//cloudwatch_dashboard_rds?ref=a383cf2dc02036029e966e3401fbbe07e77f7186"

  dashboard_name = "${var.env_name}-RDS-idp"

  region = var.region

  db_instance_identifier = aws_db_instance.idp.id
  iops                   = var.rds_iops_idp

  vertical_annotations = var.rds_dashboard_idp_vertical_annotations
}

module "elb_http_alerts" {
  source = "github.com/18F/identity-terraform//elb_http_alerts?ref=a383cf2dc02036029e966e3401fbbe07e77f7186"

  env_name         = var.env_name
  load_balancer_id = aws_alb.idp[0].id

  // These are defined in variables.tf
  alarm_actions = local.high_priority_alarm_actions
}

