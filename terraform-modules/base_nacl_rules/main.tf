# allow traffic out to get packages/gems/git
resource "aws_network_acl_rule" "egress-all-tcp-all-ports" {
  count = var.enabled
  network_acl_id = var.network_acl_id
  egress = true
  from_port = 0
  to_port = 65535
  protocol = "tcp"
  rule_number = 5
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
}

# allow ntp (if only NACLs let us specify source ports)
resource "aws_network_acl_rule" "egress-ntp" {
  count = var.enabled
  network_acl_id = var.network_acl_id
  egress = true
  from_port = 123
  to_port = 123
  protocol = "udp"
  cidr_block = "0.0.0.0/0"
  rule_number = 10
  rule_action = "allow"
}
resource "aws_network_acl_rule" "ingress-ntp-all-ports" {
  count = var.enabled
  network_acl_id = var.network_acl_id
  egress = false
  from_port = 0
  to_port = 65535
  protocol = "udp"
  rule_number = 15
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
}

# allow traffic back in from when hosts here initiate connections
# to the internet for packages and so on (ephemeral ports)
resource "aws_network_acl_rule" "ingress-tcp-ephemeral-ports" {
  count = var.enabled
  network_acl_id = var.network_acl_id
  egress = false
  from_port = 32768
  to_port = 61000
  protocol = "tcp"
  rule_number = 20
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
}

# Allow SSH in from the specified CIDR blocks
resource "aws_network_acl_rule" "ingress-tcp-ssh-cidr-blocks" {
  count = var.enabled * length(var.ssh_cidr_blocks)
  network_acl_id = var.network_acl_id
  rule_number = 25 + count.index
  egress = false
  protocol = "tcp"
  from_port = 22
  to_port = 22
  cidr_block = var.ssh_cidr_blocks[count.index]
  rule_action = "allow"
}
