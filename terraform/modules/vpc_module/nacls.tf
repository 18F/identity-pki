# Manage the special default Network ACL, which should not be used by any
# subnets. Add every subnet explicitly to one of the NACLs below so that they
# don't use this default NACL.

resource "aws_default_network_acl" "default" {
  default_network_acl_id = aws_vpc.default.default_network_acl_id

  tags = {
    Name = "${var.env_name}-default-should-not-be-used"
  }

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

#### NACL for db subnets ###

resource "aws_network_acl" "db" {
  tags = {
    Name = "${var.env_name}-db"
  }

  vpc_id     = aws_vpc.default.id
  subnet_ids = [for subnet in aws_subnet.data-services : subnet.id]
}

# allow ephemeral ports out
resource "aws_network_acl_rule" "db-egress-s-ephemeral" {
  network_acl_id = aws_network_acl.db.id
  egress         = true
  from_port      = 32768
  to_port        = 61000
  protocol       = "tcp"
  rule_number    = 6
  rule_action    = "allow"
  cidr_block     = var.secondary_cidr_block
}

resource "aws_network_acl_rule" "db-egress-nessus-ephemeral" {
  count          = var.nessus_public_access_mode ? 1 : 0
  network_acl_id = aws_network_acl.db.id
  egress         = true
  from_port      = 32768
  to_port        = 61000
  protocol       = "tcp"
  rule_number    = 7
  rule_action    = "allow"
  cidr_block     = var.nessusserver_ip
}

# let redis in
resource "aws_network_acl_rule" "db-ingress-s-redis" {
  network_acl_id = aws_network_acl.db.id
  egress         = false
  from_port      = 6379
  to_port        = 6379
  protocol       = "tcp"
  rule_number    = 11
  rule_action    = "allow"
  cidr_block     = var.secondary_cidr_block
}

# let postgres in
resource "aws_network_acl_rule" "db-ingress-s-postgres" {
  network_acl_id = aws_network_acl.db.id
  egress         = false
  from_port      = var.rds_db_port
  to_port        = var.rds_db_port
  protocol       = "tcp"
  rule_number    = 16
  rule_action    = "allow"
  cidr_block     = var.secondary_cidr_block
}

resource "aws_network_acl_rule" "db-ingress-nessus-redis" {
  count          = var.nessus_public_access_mode ? 1 : 0
  network_acl_id = aws_network_acl.db.id
  egress         = false
  from_port      = 6379
  to_port        = 6379
  protocol       = "tcp"
  rule_number    = 17
  rule_action    = "allow"
  cidr_block     = var.nessusserver_ip
}

resource "aws_network_acl_rule" "db-ingress-nessus-postgres" {
  count          = var.nessus_public_access_mode ? 1 : 0
  network_acl_id = aws_network_acl.db.id
  egress         = false
  from_port      = var.rds_db_port
  to_port        = var.rds_db_port
  protocol       = "tcp"
  rule_number    = 18
  rule_action    = "allow"
  cidr_block     = var.nessusserver_ip
}

# ---------------- end db rules ---------------

#### NACL for app subnets ###
# Uses up to rule number 25 + number of ssh_cidr_blocks

resource "aws_network_acl" "idp" {
  tags = {
    Name = "${var.env_name}-idp"
  }

  vpc_id     = aws_vpc_ipv4_cidr_block_association.secondary_cidr.vpc_id
  subnet_ids = [for subnet in aws_subnet.app : subnet.id]
}

# Uses up to rule number 25 + number of ssh_cidr_blocks
module "idp-base-nacl-rules" {
  source         = "../../modules/base_nacl_rules"
  network_acl_id = aws_network_acl.idp.id
}

resource "aws_network_acl_rule" "idp-ingress-s-http" {
  network_acl_id = aws_network_acl.idp.id
  egress         = false
  from_port      = 80
  to_port        = 80
  protocol       = "tcp"
  rule_number    = 41
  rule_action    = "allow"
  cidr_block     = var.secondary_cidr_block
}

resource "aws_network_acl_rule" "idp-ingress-s-https" {
  network_acl_id = aws_network_acl.idp.id
  egress         = false
  from_port      = 443
  to_port        = 443
  protocol       = "tcp"
  rule_number    = 49
  rule_action    = "allow"
  cidr_block     = var.secondary_cidr_block
}

resource "aws_network_acl_rule" "idp-ingress-s-proxy" {
  network_acl_id = aws_network_acl.idp.id
  egress         = false
  from_port      = 1024
  to_port        = 65535
  protocol       = "tcp"
  rule_number    = 50
  rule_action    = "allow"
  cidr_block     = var.secondary_cidr_block
}

# ------------- end idp rules --------------------