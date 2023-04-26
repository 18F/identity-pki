data "aws_caller_identity" "current" {}

data "aws_iam_account_alias" "current" {}

data "aws_lb" "alb" {
  count = var.wafv2_web_acl_scope == "REGIONAL" ? 1 : 0
  name  = var.lb_name != "" ? var.lb_name : "login-idp-alb-${var.env}"
}
