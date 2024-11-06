data "aws_caller_identity" "current" {}

data "aws_ip_ranges" "s3_cidr_blocks" {
  regions  = [var.region]
  services = ["s3"]
}

resource "aws_network_acl_rule" "db-ingress-s3-ephemeral" {
  for_each       = toset(data.aws_ip_ranges.s3_cidr_blocks.cidr_blocks)
  network_acl_id = var.network_acl_id
  egress         = false
  from_port      = 32768
  to_port        = 61000
  protocol       = "tcp"
  rule_number    = index(data.aws_ip_ranges.s3_cidr_blocks.cidr_blocks, each.value) + 20
  rule_action    = "allow"
  cidr_block     = each.value
}

resource "aws_network_acl_rule" "db-egress-s3-https" {
  for_each       = toset(data.aws_ip_ranges.s3_cidr_blocks.cidr_blocks)
  network_acl_id = var.network_acl_id
  egress         = true
  from_port      = 443
  to_port        = 443
  protocol       = "tcp"
  rule_number    = index(data.aws_ip_ranges.s3_cidr_blocks.cidr_blocks, each.value) + 20
  rule_action    = "allow"
  cidr_block     = each.value
}


