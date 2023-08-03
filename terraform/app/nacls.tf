resource "aws_network_acl" "alb" {
  vpc_id     = module.network_uw2.vpc_id
  subnet_ids = [for subnet in aws_subnet.public-ingress : subnet.id]

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
resource "aws_network_acl_rule" "alb-ingress-tcp-all-s-internal" {
  network_acl_id = aws_network_acl.alb.id
  egress         = false
  from_port      = 0
  to_port        = 65535
  protocol       = "tcp"
  rule_number    = 25
  rule_action    = "allow"
  cidr_block     = module.network_uw2.secondary_cidr
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

resource "aws_network_acl_rule" "alb-ingress-tcp-redis" {
  count          = local.nessus_public_access_mode ? 1 : 0
  network_acl_id = aws_network_acl.alb.id
  egress         = false
  from_port      = 6379
  to_port        = 6379
  protocol       = "tcp"
  rule_number    = 50
  rule_action    = "allow"
  cidr_block     = var.nessusserver_ip
}

moved {
  from = aws_default_network_acl.default
  to   = module.network_uw2.aws_default_network_acl.default
}

moved {
  from = aws_network_acl.db
  to   = module.network_uw2.aws_network_acl.db
}

moved {
  from = aws_network_acl_rule.db-egress-s-ephemeral
  to   = module.network_uw2.aws_network_acl_rule.db-egress-s-ephemeral
}

moved {
  from = aws_network_acl_rule.db-egress-nessus-ephemeral
  to   = module.network_uw2.aws_network_acl_rule.db-egress-nessus-ephemeral
}

moved {
  from = aws_network_acl_rule.db-ingress-s-redis
  to   = module.network_uw2.aws_network_acl_rule.db-ingress-s-redis
}

moved {
  from = aws_network_acl_rule.db-ingress-s-postgres
  to   = module.network_uw2.aws_network_acl_rule.db-ingress-s-postgres
}

moved {
  from = aws_network_acl_rule.db-ingress-nessus-redis
  to   = module.network_uw2.aws_network_acl_rule.db-ingress-nessus-redis
}

moved {
  from = aws_network_acl_rule.db-ingress-nessus-postgres
  to   = module.network_uw2.aws_network_acl_rule.db-ingress-nessus-postgres
}

moved {
  from = aws_network_acl.idp
  to   = module.network_uw2.aws_network_acl.idp
}

moved {
  from = module.idp-base-nacl-rules
  to   = module.network_uw2.module.idp-base-nacl-rules
}

moved {
  from = aws_network_acl_rule.idp-ingress-s-http
  to   = module.network_uw2.aws_network_acl_rule.idp-ingress-s-http
}

moved {
  from = aws_network_acl_rule.idp-ingress-s-https
  to   = module.network_uw2.aws_network_acl_rule.idp-ingress-s-https
}

moved {
  from = aws_network_acl_rule.idp-ingress-s-proxy
  to   = module.network_uw2.aws_network_acl_rule.idp-ingress-s-proxy
}
