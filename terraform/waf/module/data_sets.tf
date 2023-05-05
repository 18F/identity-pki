locals {
  app_regex_sets = [
    "restricted_paths",
    "restricted_paths_exclusions",
  ]
  acct_regex_sets = [
    "relaxed_uri_paths",
    "limit_exempt_paths",
  ]
  ip_sets = [
    "block_list_v4",
    "block_list_v6",
    "privileged_ips_v4",
    "privileged_ips_v6",
  ]
}

data "aws_wafv2_regex_pattern_set" "header_blocks" {
  count = length(var.header_block_regex)
  name  = "${local.tf_acct}-header-${var.header_block_regex[count.index].field_name}-blocks"
  scope = var.wafv2_web_acl_scope
}

data "aws_wafv2_regex_pattern_set" "app" {
  for_each = toset(local.app_regex_sets)
  name     = "${local.tf_acct}-${var.app}-${replace(each.key, "_", "-")}"
  scope    = var.wafv2_web_acl_scope
}

data "aws_wafv2_regex_pattern_set" "acct" {
  for_each = toset(local.acct_regex_sets)
  name     = "${local.tf_acct}-${replace(each.key, "_", "-")}"
  scope    = var.wafv2_web_acl_scope
}

data "aws_wafv2_ip_set" "acl" {
  for_each = toset(local.ip_sets)
  name     = "${local.tf_acct}-${var.app}-${replace(each.key, "_", "-")}"
  scope    = var.wafv2_web_acl_scope
}
