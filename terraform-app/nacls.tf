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

# A default network ACL that allows all traffic
resource "aws_network_acl" "allow" {
  tags = {
    Name = "${var.env_name}-allow"
  }

  vpc_id = aws_vpc.default.id

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

  # Add basically every subnet here.
  subnet_ids = [
    aws_subnet.publicsubnet1.id,
    aws_subnet.publicsubnet2.id,
    aws_subnet.publicsubnet3.id,
    aws_subnet.privatesubnet1.id,
    aws_subnet.privatesubnet2.id,
    aws_subnet.privatesubnet3.id,
  ]
}

resource "aws_network_acl" "db" {
  tags = {
    Name = "${var.env_name}-db"
  }

  vpc_id     = aws_vpc.default.id
  subnet_ids = [aws_subnet.db1.id, aws_subnet.db2.id]
}

# allow ephemeral ports out
resource "aws_network_acl_rule" "db-egress-ephemeral" {
  network_acl_id = aws_network_acl.db.id
  egress         = true
  from_port      = 32768
  to_port        = 61000
  protocol       = "tcp"
  rule_number    = 5
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr_block
}

# let redis in
resource "aws_network_acl_rule" "db-ingress-redis" {
  network_acl_id = aws_network_acl.db.id
  egress         = false
  from_port      = 6379
  to_port        = 6379
  protocol       = "tcp"
  rule_number    = 10
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr_block
}

# let postgres in
resource "aws_network_acl_rule" "db-ingress-postgres" {
  network_acl_id = aws_network_acl.db.id
  egress         = false
  from_port      = 5432
  to_port        = 5432
  protocol       = "tcp"
  rule_number    = 15
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr_block
}

# ---------------- end db rules ---------------

resource "aws_network_acl" "jumphost" {
  tags = {
    Name = "${var.env_name}-jumphost"
  }

  vpc_id = aws_vpc.default.id
  subnet_ids = [
    aws_subnet.jumphost1.id,
    aws_subnet.jumphost2.id,
  ]
}

# Uses up to rule number 25 + number of ssh_cidr_blocks
module "jumphost-base-nacl-rules" {
  source         = "../terraform-modules/base_nacl_rules"
  network_acl_id = aws_network_acl.jumphost.id
  ssh_cidr_blocks = flatten([
    var.jumphost1_subnet_cidr_block,
    var.jumphost2_subnet_cidr_block,
    var.app_sg_ssh_cidr_blocks,
    var.ci_sg_ssh_cidr_blocks,
  ])
}

resource "aws_network_acl_rule" "jumphost-elb-healthcheck1" {
  network_acl_id = aws_network_acl.jumphost.id
  egress         = false
  from_port      = 26
  to_port        = 26
  protocol       = "tcp"
  cidr_block     = var.jumphost1_subnet_cidr_block
  rule_number    = 50
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "jumphost-elb-healthcheck2" {
  network_acl_id = aws_network_acl.jumphost.id
  egress         = false
  from_port      = 26
  to_port        = 26
  protocol       = "tcp"
  cidr_block     = var.jumphost2_subnet_cidr_block
  rule_number    = 51
  rule_action    = "allow"
}

resource "aws_network_acl" "idp" {
  tags = {
    Name = "${var.env_name}-idp"
  }

  vpc_id     = aws_vpc.default.id
  subnet_ids = [
    aws_subnet.idp1.id,
    aws_subnet.idp2.id,
  ]
}

# Uses up to rule number 25 + number of ssh_cidr_blocks
module "idp-base-nacl-rules" {
  source         = "../terraform-modules/base_nacl_rules"
  network_acl_id = aws_network_acl.idp.id
  ssh_cidr_blocks = flatten([
    var.jumphost1_subnet_cidr_block,
    var.jumphost2_subnet_cidr_block,
    var.ci_sg_ssh_cidr_blocks,
  ])
}

resource "aws_network_acl_rule" "idp-ingress-http" {
  network_acl_id = aws_network_acl.idp.id
  egress         = false
  from_port      = 80
  to_port        = 80
  protocol       = "tcp"
  rule_number    = 40
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr_block
}

resource "aws_network_acl_rule" "idp-ingress-https" {
  network_acl_id = aws_network_acl.idp.id
  egress         = false
  from_port      = 443
  to_port        = 443
  protocol       = "tcp"
  rule_number    = 45
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr_block
}

# The cloudhsm cluster is in the idp subnet, must allow access from the IDP
# subnets in other AZs
resource "aws_network_acl_rule" "idp-ingress-cloudhsm" {
  network_acl_id = aws_network_acl.idp.id
  egress         = false
  from_port      = 2223
  to_port        = 2225
  protocol       = "tcp"
  rule_number    = 46
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr_block
}

# ------------- end idp rules --------------------

resource "aws_network_acl" "alb" {
  vpc_id     = aws_vpc.default.id
  subnet_ids = [aws_subnet.alb1.id, aws_subnet.alb2.id, aws_subnet.alb3.id]

  tags = {
    Name = "${var.env_name}-alb"
  }
}

resource "aws_network_acl_rule" "alb-egress-tcp-all-egress" {
  network_acl_id = aws_network_acl.alb.id
  egress         = true
  from_port      = 0
  to_port        = 65535
  protocol       = "tcp"
  rule_number    = 10
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

# allow traffic back in from when the ALBs do healthchecks
resource "aws_network_acl_rule" "alb-ingress-tcp-all-internal" {
  network_acl_id = aws_network_acl.alb.id
  egress         = false
  from_port      = 0
  to_port        = 65535
  protocol       = "tcp"
  rule_number    = 20
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr_block
}

resource "aws_network_acl_rule" "alb-ingress-tcp-http" {
  network_acl_id = aws_network_acl.alb.id
  egress         = false
  from_port      = 80
  to_port        = 80
  protocol       = "tcp"
  rule_number    = 30
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "alb-ingress-tcp-https" {
  network_acl_id = aws_network_acl.alb.id
  egress         = false
  from_port      = 443
  to_port        = 443
  protocol       = "tcp"
  rule_number    = 40
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

