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
  count              = length(var.privileged_ips) > 0 ? 1 : 0
  name               = "${local.web_acl_name}-privileged-ips"
  description        = "Privileged IPs"
  scope              = var.wafv2_web_acl_scope
  ip_address_version = "IPV4"
  addresses          = var.privileged_ips
  tags = {
    environment = var.env
  }
}
