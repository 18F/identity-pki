# Base security group added to all instances, grants default permissions like
# ingress SSH and ICMP.
resource "aws_security_group" "base" {
  name        = "${var.env_name}-base"
  description = "Base security group for rules common to all instances"
  vpc_id      = aws_vpc.default.id

  tags = {
    Name = "${var.env_name}-base"
  }

  # allow ICMP to/from the whole VPC
  ingress {
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  egress {
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  # allow access to the VPC private S3 endpoint
  egress {
    description     = "allow egress to VPC S3 endpoint"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.private-s3.prefix_list_id]
  }

  egress {
    description = "allow egress to other VPC endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [
      aws_security_group.ec2_endpoint.id,
      aws_security_group.ec2messages_endpoint.id,
      aws_security_group.logs_endpoint.id,
      aws_security_group.monitoring_endpoint.id,
      aws_security_group.secretsmanager_endpoint.id,
      aws_security_group.smtp_endpoint.id,
      aws_security_group.sns_endpoint.id,
      aws_security_group.ssm_endpoint.id,
      aws_security_group.ssmmessages_endpoint.id,
      aws_security_group.sts_endpoint.id,
      aws_security_group.kms_endpoint.id
    ]
  }

  # GARBAGE TEMP - Allow direct access to api.snapcraft.io until Ubuntu Advantage stops
  #                hanging on repeated calls to pull the livestream agent from snap
  egress {
    description = "allow egress to api.snapcraft.io"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["91.189.92.0/24"]
  }

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.github_ipv4_cidr_blocks
  }

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.gitlab_lb_interface_cidr_blocks
    description = "Allow connection to NLB"
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = local.gitlab_lb_interface_cidr_blocks
    description = "Allow connection to NLB"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "gitlab" {
  description = "Allow inbound gitlab traffic: allowlisted IPs for SSH"

  # TODO: limit this to what is actually needed
  # allow outbound to the VPC so that we can get to db/redis/logstash/etc.

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  # can talk to the proxy
  egress {
    from_port   = var.proxy_port
    to_port     = var.proxy_port
    protocol    = "tcp"
    cidr_blocks = module.outbound_proxy.proxy_lb_cidr_blocks
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [for zone in local.network_zones : local.network_layout[var.region][var.env_type]["_zones"][zone]["data-services"]["ipv4-cidr"]]
  }

  egress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [for zone in local.network_zones : local.network_layout[var.region][var.env_type]["_zones"][zone]["data-services"]["ipv4-cidr"]]
  }

  # need 8834 to comm with Nessus Server
  egress {
    from_port   = 8834
    to_port     = 8834
    protocol    = "tcp"
    cidr_blocks = [var.nessusserver_ip]
  }

  # these cidr blocks should contain the nlb, so it can do healthchecks and send traffic
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = sort(
      concat(
        [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block],
        local.github_ipv4_cidr_blocks,
        var.allowed_gitlab_cidr_blocks_v4
      )
    )
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = sort(
      concat(
        [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block],
        data.github_ip_ranges.meta.hooks_ipv4,
        var.allowed_gitlab_cidr_blocks_v4
      )
    )
  }

  # Accept traffic from the WAF-enabled ALB
  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    security_groups = [
      aws_security_group.waf_alb.id,
    ]
  }

  # these are the EIPs for the NAT which is being used by the obproxies
  # This is needed so that the outbound proxies can access the external lb.
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for zone in local.network_zones : "${aws_nat_gateway.nat[zone].public_ip}/32"]
  }

  # these cidr blocks should contain the nlb, so it can do healthchecks and send traffic
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.gitlab_lb_interface_cidr_blocks
    description = "Allow connection from NLB"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = local.gitlab_lb_interface_cidr_blocks
    description = "Allow connection from NLB"
  }

  name_prefix = "${var.name}-gitlab-${var.env_name}"

  tags = {
    Name = "${var.name}-gitlabserver_security_group-${var.env_name}"
    role = "gitlab"
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group" "cache" {
  description = "Allow inbound and outbound redis traffic with app subnet in vpc"

  ingress {
    from_port = 6379
    to_port   = 6379
    protocol  = "tcp"
    security_groups = [
      aws_security_group.gitlab.id,
    ]
  }

  name_prefix = "${var.name}-cache-${var.env_name}"

  tags = {
    Name = "${var.name}-cache_security_group-${var.env_name}"
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group" "db" {
  description = "Allow inbound and outbound postgresql traffic to proper locations"

  egress = []

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    security_groups = [
      aws_security_group.gitlab.id,
    ]
  }

  name = "${var.name}-db-${var.env_name} gitlab"

  tags = {
    Name = "${var.name}-db_security_group-${var.env_name} gitlab"
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group" "ec2_endpoint" {
  name_prefix = "${var.name}-ec2_endpoint-${var.env_name}"
  description = "Allow inbound from all servers"

  # allow outbound to the VPC
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  tags = {
    Name = "${var.name}-ec2_endpoint-${var.env_name}"
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group" "ec2messages_endpoint" {
  name_prefix = "${var.name}-ec2messages_endpoint-${var.env_name}"
  description = "Allow inbound from all servers"

  # allow outbound to the VPC
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }
  # Adding ingress rule below to allow ssm access via port 443 from private and idp subnets
  # This rule was created to avoid circular dependencies and allow quarantine hosts to be managed via ssm

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  tags = {
    Name = "${var.name}-ec2messages_endpoint-${var.env_name}"
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group" "logs_endpoint" {
  name_prefix = "${var.name}-logs_endpoint-${var.env_name}"
  description = "Allow inbound from all servers"

  # allow outbound to the VPC
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  # Adding ingress rule below to allow ssm access via port 443 from private and idp subnets
  # This rule was created to avoid circular dependencies and allow quarantine hosts to be managed via ssm

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  tags = {
    Name = "${var.name}-logs_endpoint-${var.env_name}"
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group" "monitoring_endpoint" {
  name_prefix = "${var.name}-monitoring_endpoint-${var.env_name}"
  description = "Allow inbound from all servers"

  # allow outbound to the VPC
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  tags = {
    Name = "${var.name}-monitoring_endpoint-${var.env_name}"
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group" "secretsmanager_endpoint" {
  name_prefix = "${var.name}-secretsmanager_endpoint-${var.env_name}"
  description = "Allow inbound from all servers"

  # allow outbound to the VPC
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  tags = {
    Name = "${var.name}-secretsmanager_endpoint-${var.env_name}"
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group" "sns_endpoint" {
  name_prefix = "${var.name}-sns_endpoint-${var.env_name}"
  description = "Allow inbound from all servers"

  # allow outbound to the VPC
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  tags = {
    Name = "${var.name}-sns_endpoint-${var.env_name}"
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group" "smtp_endpoint" {
  description = "Allow inbound from all servers"

  # allow outbound to the VPC
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group" "sts_endpoint" {
  description = "Allow inbound from all servers"

  # allow outbound to the VPC
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group" "events_endpoint" {
  description = "Allow inbound from all servers"

  # allow outbound to the VPC
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group" "ssm_endpoint" {
  name_prefix = "${var.name}-ssm_endpoint-${var.env_name}"
  description = "Allow inbound from all servers"

  # allow outbound to the VPC
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  # Adding ingress rule below to allow ssm access via port 443 from private and idp subnets
  # This rule was created to avoid circular dependencies and allow quarantine hosts to be managed via ssm

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.default.id
}


resource "aws_security_group" "ssmmessages_endpoint" {
  name_prefix = "${var.name}-ssmmessages_endpoint-${var.env_name}"
  description = "Allow inbound from all servers"

  # allow outbound to the VPC
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  # Adding ingress rule below to allow ssm access via port 443 from private and idp subnets
  # This rule was created to avoid circular dependencies and allow quarantine hosts to be managed via ssm

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group" "kms_endpoint" {
  name_prefix = "${var.name}-kms_endpoint-${var.env_name}"
  description = "Allow inbound from all servers"

  # allow outbound to the VPC
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group" "waf_alb" {
  name        = "${var.env_name}-waf-alb"
  description = "Allow inbound from the NLB to the WAF-enabled ALB"
  vpc_id      = aws_vpc.default.id
}

resource "aws_security_group_rule" "waf_lb_nlb_ingress" {
  count             = var.use_waf_rules ? 0 : 1
  security_group_id = aws_security_group.waf_alb.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = local.gitlab_lb_interface_cidr_blocks
  description       = "Allow connection from NLB"
}

resource "aws_security_group_rule" "waf_lb_nat_ingress" {
  count             = var.use_waf_rules ? 0 : 1
  security_group_id = aws_security_group.waf_alb.id
  type              = "ingress"
  description       = "These are the EIPs for the NAT which is being used by the obproxies. This is needed so that the outbound proxies can access the external lb"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [for zone in local.network_zones : "${aws_nat_gateway.nat[zone].public_ip}/32"]
}

resource "aws_security_group_rule" "waf_lb_vpc_vpn_ingress" {
  count             = var.use_waf_rules ? 0 : 1
  security_group_id = aws_security_group.waf_alb.id
  type              = "ingress"
  description       = "Source IPs conneting through the NLB"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks = sort(
    concat(
      [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block],
      data.github_ip_ranges.meta.hooks_ipv4,
      var.allowed_gitlab_cidr_blocks_v4
    )
  )
}

resource "aws_security_group_rule" "waf_lb_public_ingress" {
  count             = var.use_waf_rules ? 1 : 0 # This is opposite the other rules.
  security_group_id = aws_security_group.waf_alb.id
  type              = "ingress"
  description       = "Alow public HTTPS traffic. Filtering occurs at the WAF level"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0", ]
}

resource "aws_security_group_rule" "waf_lb_vpc_egress" {
  security_group_id = aws_security_group.waf_alb.id
  type              = "egress"
  description       = "Allow outbound to the VPC"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
}


resource "aws_security_group" "rds_endpoint" {
  name_prefix = "${var.name}-rds_endpoint-${var.env_name}"
  description = "Allow inbound from all servers"

  # allow outbound to the VPC
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.default.id
}