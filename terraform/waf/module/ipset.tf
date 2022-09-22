resource "aws_wafv2_ip_set" "block_list" {
  name               = "${local.web_acl_name}-block-list"
  description        = "${local.web_acl_name} ip block list"
  scope              = var.wafv2_web_acl_scope
  ip_address_version = "IPV4"
  addresses          = var.ip_block_list

  tags = {
    environment = var.env
  }
}

resource "aws_wafv2_ip_set" "privileged_ips" {
  count              = length(var.privileged_cidrs_v4) > 0 ? 1 : 0
  name               = "${local.web_acl_name}-privileged-ips"
  description        = "Privileged IPv4 CIDRs"
  scope              = var.wafv2_web_acl_scope
  ip_address_version = "IPV4"
  addresses          = var.privileged_cidrs_v4
  tags = {
    environment = var.env
  }
}

resource "aws_wafv2_ip_set" "privileged_cidrs_v6" {
  count              = length(var.privileged_cidrs_v6) > 0 ? 1 : 0
  name               = "${local.web_acl_name}-privileged-cidrs-v6"
  description        = "Privileged IPv6 CIDRs"
  scope              = var.wafv2_web_acl_scope
  ip_address_version = "IPV6"
  addresses          = var.privileged_cidrs_v6
  tags = {
    environment = var.env
  }
}

