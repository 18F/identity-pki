resource "aws_wafv2_ip_set" "block_list" {
  name               = "${local.web_acl_name}-block-list"
  description        = "${local.web_acl_name} IPv4 Block List"
  scope              = var.wafv2_web_acl_scope
  ip_address_version = "IPV4"
  addresses          = var.ip_block_cidrs_v4

  tags = {
    environment = var.env
  }
}

resource "aws_wafv2_ip_set" "block_list_v6" {
  count = length(var.ip_block_cidrs_v6) > 0 ? 1 : 0

  name               = "${local.web_acl_name}-block-list-v6"
  description        = "${local.web_acl_name} IPv6 Block List"
  scope              = var.wafv2_web_acl_scope
  ip_address_version = "IPV6"
  addresses          = var.ip_block_cidrs_v6

  tags = {
    environment = var.env
  }
}

resource "aws_wafv2_ip_set" "privileged_ips" {
  count              = length(var.privileged_cidrs_v4) > 0 ? 1 : 0
  name               = "${local.web_acl_name}-privileged-ips"
  description        = "${local.web_acl_name} Privileged IPv4 CIDRs"
  scope              = var.wafv2_web_acl_scope
  ip_address_version = "IPV4"
  addresses          = var.privileged_cidrs_v4
  tags = {
    environment = var.env
  }
}

resource "aws_wafv2_ip_set" "privileged_ips_v6" {
  count              = length(var.privileged_cidrs_v6) > 0 ? 1 : 0
  name               = "${local.web_acl_name}-privileged-ips-v6"
  description        = "${local.web_acl_name} Privileged IPv6 CIDRs"
  scope              = var.wafv2_web_acl_scope
  ip_address_version = "IPV6"
  addresses          = var.privileged_cidrs_v6
  tags = {
    environment = var.env
  }
}

