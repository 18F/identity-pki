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
  ]
}

resource "aws_network_acl" "gitlab" {
  tags = {
    Name = "${var.env_name}-gitlab"
  }

  vpc_id = aws_vpc.default.id
  subnet_ids = [
    aws_subnet.gitlab1.id,
    aws_subnet.gitlab2.id,
  ]
}

# Uses up to rule number 25 + number of ssh_cidr_blocks
module "gitlab-base-nacl-rules" {
  source         = "../../modules/base_nacl_rules"
  network_acl_id = aws_network_acl.gitlab.id
  ssh_cidr_blocks = flatten([
    var.gitlab1_subnet_cidr_block,
    var.gitlab2_subnet_cidr_block,
    var.ci_sg_ssh_cidr_blocks,
  ])
}

resource "aws_network_acl_rule" "gitlab-elb-healthcheck1" {
  network_acl_id = aws_network_acl.gitlab.id
  egress         = false
  from_port      = 26
  to_port        = 26
  protocol       = "tcp"
  cidr_block     = var.gitlab1_subnet_cidr_block
  rule_number    = 50
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "gitlab-elb-healthcheck2" {
  network_acl_id = aws_network_acl.gitlab.id
  egress         = false
  from_port      = 26
  to_port        = 26
  protocol       = "tcp"
  cidr_block     = var.gitlab2_subnet_cidr_block
  rule_number    = 51
  rule_action    = "allow"
}

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

resource "aws_network_acl_rule" "gitlab-ingress-https" {
  network_acl_id = aws_network_acl.gitlab.id
  egress         = false
  from_port      = 443
  to_port        = 443
  protocol       = "tcp"
  rule_number    = 45
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr_block
}
