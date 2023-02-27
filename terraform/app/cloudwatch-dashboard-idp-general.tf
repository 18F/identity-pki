# cloudwatch dashboard for IDP
module "idp_dashboard" {
  source = "github.com/18F/identity-terraform//cloudwatch_dashboard_alb?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/cloudwatch_dashboard_alb"

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
