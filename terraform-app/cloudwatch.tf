
# cloudwatch dashboard for IDP
module "idp_dashboard" {
    source = "github.com/18F/identity-terraform//cloudwatch_dashboard_alb?ref=021ba1813c0c5f888bd439591618e10308098475"

    enabled = "${var.alb_enabled}"

    dashboard_name = "${var.env_name}-idp"
    alb_arn_suffix = "${aws_alb.idp.arn_suffix}"
    target_group_label = "${var.env_name} IDP"
    target_group_arn_suffix = "${aws_alb_target_group.idp-ssl.arn_suffix}"
}

output "idp_dashboard_arn" {
    value = "${module.idp_dashboard.dashboard_arn}"
}
