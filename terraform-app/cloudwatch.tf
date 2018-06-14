
# cloudwatch dashboard for IDP
module "idp_dashboard" {
    source = "github.com/18F/identity-terraform//cloudwatch_dashboard_alb?ref=62385b497f5b8dba2478be5759d53c1fb2353185"

    enabled = "${var.alb_enabled}"

    dashboard_name = "${var.env_name}-idp"
    alb_arn_suffix = "${aws_alb.idp.arn_suffix}"
    target_group_label = "${var.env_name} IDP"
    target_group_arn_suffix = "${aws_alb_target_group.idp-ssl.arn_suffix}"
}

output "idp_dashboard_arn" {
    value = "${module.idp_dashboard.dashboard_arn}"
}
