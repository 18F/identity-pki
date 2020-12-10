resource "aws_wafv2_ip_set" "block_list" {
  name               = "${local.web_acl_name}-block-list"
  description        = "${local.web_acl_name} ip block list"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = var.ip_block_list

  tags = {
    environment = var.env
  }
}