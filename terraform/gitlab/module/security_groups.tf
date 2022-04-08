# Base security group added to all instances, grants default permissions like
# ingress SSH and ICMP.
resource "aws_security_group" "base" {
  name        = "${var.env_name}-base"
  description = "Base security group for rules common to all instances"
  vpc_id      = aws_vpc.default.id

  tags = {
    Name = "${var.env_name}-base"
  }

  # allow TCP egress to outbound proxy
  egress {
    description     = "allow egress to outbound proxy"
    protocol        = "tcp"
    from_port       = var.proxy_port
    to_port         = var.proxy_port
    security_groups = [module.outbound_proxy.proxy_security_group_id]
  }

  # allow ICMP to/from the whole VPC
  ingress {
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = [aws_vpc.default.cidr_block]
  }

  egress {
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = [aws_vpc.default.cidr_block]
  }

  # allow access to the VPC private S3 endpoint
  egress {
    description     = "allow egress to VPC S3 endpoint"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.private-s3.prefix_list_id]
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
    cidr_blocks = [aws_vpc.default.cidr_block]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.db1.cidr_block, aws_subnet.db2.cidr_block]
  }

  egress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.db1.cidr_block, aws_subnet.db2.cidr_block]
  }

  # need 8834 to comm with Nessus Server
  egress {
    from_port   = 8834
    to_port     = 8834
    protocol    = "tcp"
    cidr_blocks = [var.nessusserver_ip]
  }

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.github_ipv4_cidr_blocks
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.gitlab-lb.id]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.gitlab-lb.id]
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

resource "aws_security_group" "gitlab-lb" {
  description = "Allow inbound gitlab traffic from allowlisted IPs"

  # TODO: limit this to what is actually needed
  # allow outbound to the VPC so that we can get to db/redis/logstash/etc.
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_gitlab_cidr_blocks_v4
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = sort(concat(var.allowed_gitlab_cidr_blocks_v4, data.github_ip_ranges.meta.hooks_ipv4))
  }

  # these are the EIPs for the NAT which is being used by the obproxies
  # This is needed so that the outbound proxies can access the external lb.
  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [
      "${aws_eip.nat_a.public_ip}/32",
      "${aws_eip.nat_b.public_ip}/32",
      "${aws_eip.nat_c.public_ip}/32"
    ]
  }

  name_prefix = "${var.name}-gitlab-lb-${var.env_name}"

  tags = {
    Name = "${var.name}-gitlab-lb_security_group-${var.env_name}"
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
    cidr_blocks = [aws_vpc.default.cidr_block]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block]
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
    cidr_blocks = [aws_vpc.default.cidr_block]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block]
  }
  # Adding ingress rule below to allow ssm access via port 443 from private and idp subnets
  # This rule was created to avoid circular dependencies and allow quarantine hosts to be managed via ssm

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block]
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
    cidr_blocks = [aws_vpc.default.cidr_block]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block]
  }

  # Adding ingress rule below to allow ssm access via port 443 from private and idp subnets
  # This rule was created to avoid circular dependencies and allow quarantine hosts to be managed via ssm

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block]
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
    cidr_blocks = [aws_vpc.default.cidr_block]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block]
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
    cidr_blocks = [aws_vpc.default.cidr_block]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block]
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
    cidr_blocks = [aws_vpc.default.cidr_block]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block]
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
    cidr_blocks = [aws_vpc.default.cidr_block]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block]
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
    cidr_blocks = [aws_vpc.default.cidr_block]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block]
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
    cidr_blocks = [aws_vpc.default.cidr_block]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block]
  }

  # Adding ingress rule below to allow ssm access via port 443 from private and idp subnets
  # This rule was created to avoid circular dependencies and allow quarantine hosts to be managed via ssm

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block]
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
    cidr_blocks = [aws_vpc.default.cidr_block]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block]
  }

  # Adding ingress rule below to allow ssm access via port 443 from private and idp subnets
  # This rule was created to avoid circular dependencies and allow quarantine hosts to be managed via ssm

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block]
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.default.id
}
