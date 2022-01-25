resource "aws_security_group" "ssm_endpoint" {
  name_prefix = "${var.name}-ssm_endpoint-${var.env_name}"
  description = "Allow inbound from all servers"

  # allow outbound to the VPC
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    security_groups = [
      aws_security_group.base.id,
      aws_security_group.gitlab.id, # TODO remove
    ]
  }

  # Adding ingress rule below to allow ssm access via port 443 from private and idp subnets
  # This rule was created to avoid circular dependencies and allow quarantine hosts to be managed via ssm

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [
      var.private1_subnet_cidr_block,
      var.private2_subnet_cidr_block,
      var.private3_subnet_cidr_block,
    ]
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
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    security_groups = [
      aws_security_group.base.id,
      aws_security_group.gitlab.id, # TODO remove
    ]
  }

  # Adding ingress rule below to allow ssm access via port 443 from private and idp subnets
  # This rule was created to avoid circular dependencies and allow quarantine hosts to be managed via ssm

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [
      var.private1_subnet_cidr_block,
      var.private2_subnet_cidr_block,
      var.private3_subnet_cidr_block,
    ]
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
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    security_groups = [
      aws_security_group.base.id,
      aws_security_group.gitlab.id, # TODO remove
    ]
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
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    security_groups = [
      aws_security_group.base.id,
      aws_security_group.gitlab.id, # TODO remove
    ]
  }
  # Adding ingress rule below to allow ssm access via port 443 from private and idp subnets
  # This rule was created to avoid circular dependencies and allow quarantine hosts to be managed via ssm

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [
      var.private1_subnet_cidr_block,
      var.private2_subnet_cidr_block,
      var.private3_subnet_cidr_block,
    ]
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
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    security_groups = [
      aws_security_group.base.id,
      aws_security_group.gitlab.id, # TODO remove
    ]
  }

  # Adding ingress rule below to allow ssm access via port 443 from private and idp subnets
  # This rule was created to avoid circular dependencies and allow quarantine hosts to be managed via ssm

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [
      var.private1_subnet_cidr_block,
      var.private2_subnet_cidr_block,
      var.private3_subnet_cidr_block,
    ]
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
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    security_groups = [
      aws_security_group.base.id,
      aws_security_group.gitlab.id, # TODO remove
    ]
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
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    security_groups = [
      aws_security_group.base.id,
      aws_security_group.gitlab.id, # TODO remove
    ]
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
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    security_groups = [
      aws_security_group.base.id,
    ]
  }

  tags = {
    Name = "${var.name}-sns_endpoint-${var.env_name}"
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.logs_endpoint.id,
  ]

  subnet_ids = [
    aws_subnet.privatesubnet1.id,
    aws_subnet.privatesubnet2.id,
    aws_subnet.privatesubnet3.id,
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "monitoring" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.monitoring"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.monitoring_endpoint.id,
  ]

  subnet_ids = [
    aws_subnet.privatesubnet1.id,
    aws_subnet.privatesubnet2.id,
    aws_subnet.privatesubnet3.id,
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.ssm_endpoint.id,
  ]

  subnet_ids = [
    aws_subnet.privatesubnet1.id,
    aws_subnet.privatesubnet2.id,
    aws_subnet.privatesubnet3.id,
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.ssmmessages_endpoint.id,
  ]

  subnet_ids = [
    aws_subnet.privatesubnet1.id,
    aws_subnet.privatesubnet2.id,
    aws_subnet.privatesubnet3.id,
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ec2" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.ec2"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.ec2_endpoint.id,
  ]

  subnet_ids = [
    aws_subnet.privatesubnet1.id,
    aws_subnet.privatesubnet2.id,
    aws_subnet.privatesubnet3.id,
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.ec2messages_endpoint.id,
  ]

  subnet_ids = [
    aws_subnet.privatesubnet1.id,
    aws_subnet.privatesubnet2.id,
    aws_subnet.privatesubnet3.id,
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.secretsmanager_endpoint.id,
  ]

  subnet_ids = [
    aws_subnet.privatesubnet1.id,
    aws_subnet.privatesubnet2.id,
    aws_subnet.privatesubnet3.id,
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "sns" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.sns"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.sns_endpoint.id,
  ]

  subnet_ids = [
    aws_subnet.privatesubnet1.id,
    aws_subnet.privatesubnet2.id,
    aws_subnet.privatesubnet3.id,
  ]

  private_dns_enabled = true
}

resource "aws_security_group" "sts_endpoint" {
  description = "Allow inbound from all servers"

  # allow outbound to the VPC
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    security_groups = [
      aws_security_group.base.id,
    ]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [
      var.private1_subnet_cidr_block,
      var.private2_subnet_cidr_block,
      var.private3_subnet_cidr_block,
    ]
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_vpc_endpoint" "sts" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.sts"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.sts_endpoint.id,
  ]

  subnet_ids = [
    aws_subnet.privatesubnet1.id,
    aws_subnet.privatesubnet2.id,
    aws_subnet.privatesubnet3.id,
  ]

  private_dns_enabled = true
}

resource "aws_security_group" "smtp_endpoint" {
  description = "Allow inbound from all servers"

  # allow outbound to the VPC
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    security_groups = [
      aws_security_group.base.id,
    ]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [
      var.private1_subnet_cidr_block,
      var.private2_subnet_cidr_block,
      var.private3_subnet_cidr_block,
    ]
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.default.id
}

data "aws_vpc_endpoint_service" "email-smtp" {
  service      = "email-smtp"
  service_type = "Interface"
}

resource "aws_vpc_endpoint" "email-smtp" {
  vpc_id             = aws_vpc.default.id
  service_name       = data.aws_vpc_endpoint_service.email-smtp.service_name
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.smtp_endpoint.id]
  subnet_ids = [
    aws_subnet.privatesubnet1.id,
    aws_subnet.privatesubnet2.id,
    aws_subnet.privatesubnet3.id,
  ]
  private_dns_enabled = true
}
