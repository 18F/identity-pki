resource "aws_security_group" "kms_endpoint" {
  description = "Allow inbound from idp servers"

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    security_groups = [
      aws_security_group.base.id
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

  name = "${var.name}-kms_endpoint-${var.env_name}"

  tags = {
    Name = "${var.name}-kms_endpoint-${var.env_name}"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group" "ssm_endpoint" {
  description = "Allow inbound from all servers"

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    security_groups = [
      aws_security_group.base.id,
      aws_security_group.jumphost.id, # TODO remove
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
      var.idp1_subnet_cidr_block,
      var.idp2_subnet_cidr_block,
    ]
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group" "ssmmessages_endpoint" {
  description = "Allow inbound from all servers"

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    security_groups = [
      aws_security_group.base.id,
      aws_security_group.jumphost.id, # TODO remove
    ]
  }

  # Adding ingress rule below to allow ssm access via port 443 from private and idp subnets
  # This rule was created to avoid circular dependencies and allow quarantine hosts to be managed via ssm

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [
      var.idp1_subnet_cidr_block,
      var.idp2_subnet_cidr_block,
      var.private1_subnet_cidr_block,
      var.private2_subnet_cidr_block,
      var.private3_subnet_cidr_block,
    ]
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group" "ec2_endpoint" {
  description = "Allow inbound from all servers"

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    security_groups = [
      aws_security_group.base.id,
      aws_security_group.jumphost.id, # TODO remove
    ]
  }

  name = "${var.name}-ec2_endpoint-${var.env_name}"

  tags = {
    Name = "${var.name}-ec2_endpoint-${var.env_name}"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group" "ec2messages_endpoint" {
  description = "Allow inbound from all servers"

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    security_groups = [
      aws_security_group.base.id,
      aws_security_group.jumphost.id, # TODO remove
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
      var.idp1_subnet_cidr_block,
      var.idp2_subnet_cidr_block,
    ]
  }

  name = "${var.name}-ec2messages_endpoint-${var.env_name}"

  tags = {
    Name = "${var.name}-ec2messages_endpoint-${var.env_name}"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group" "logs_endpoint" {
  description = "Allow inbound from all servers"

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    security_groups = [
      aws_security_group.base.id,
      aws_security_group.jumphost.id, # TODO remove
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
      var.idp1_subnet_cidr_block,
      var.idp2_subnet_cidr_block,
    ]
  }

  name = "${var.name}-logs_endpoint-${var.env_name}"

  tags = {
    Name = "${var.name}-logs_endpoint-${var.env_name}"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group" "monitoring_endpoint" {
  description = "Allow inbound from all servers"

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    security_groups = [
      aws_security_group.base.id,
      aws_security_group.jumphost.id, # TODO remove
    ]
  }

  name = "${var.name}-monitoring_endpoint-${var.env_name}"

  tags = {
    Name = "${var.name}-monitoring_endpoint-${var.env_name}"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group" "secretsmanager_endpoint" {
  description = "Allow inbound from all servers"

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    security_groups = [
      aws_security_group.base.id,
      aws_security_group.jumphost.id, # TODO remove
    ]
  }

  name = "${var.name}-secretsmanager_endpoint-${var.env_name}"

  tags = {
    Name = "${var.name}-secretsmanager_endpoint-${var.env_name}"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group" "sns_endpoint" {
  description = "Allow inbound from all servers"

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    security_groups = [
      aws_security_group.base.id,
    ]
  }

  name = "${var.name}-sns_endpoint-${var.env_name}"

  tags = {
    Name = "${var.name}-sns_endpoint-${var.env_name}"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group" "lambda_endpoint" {
  description = "Allow inbound from idp servers"

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    security_groups = [
      aws_security_group.idp.id,
    ]
  }

  name = "${var.name}-lambda_endpoint-${var.env_name}"

  tags = {
    Name = "${var.name}-lambda_endpoint-${var.env_name}"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group" "sqs_endpoint" {
  description = "Allow inbound from idp servers"

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    security_groups = [
      aws_security_group.idp.id,
    ]
  }

  name = "${var.name}-sqs_endpoint-${var.env_name}"

  tags = {
    Name = "${var.name}-sqs_endpoint-${var.env_name}"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_vpc_endpoint" "kms" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.kms"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.kms_endpoint.id,
  ]

  subnet_ids = [
    aws_subnet.privatesubnet1.id,
    aws_subnet.privatesubnet2.id,
    aws_subnet.privatesubnet3.id,
  ]

  private_dns_enabled = true
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

resource "aws_vpc_endpoint" "lambda" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.lambda"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.lambda_endpoint.id,
  ]

  subnet_ids = [
    aws_subnet.privatesubnet1.id,
    aws_subnet.privatesubnet2.id,
    aws_subnet.privatesubnet3.id,
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "sqs" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.sqs"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.sqs_endpoint.id,
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

  ingress {
    from_port = 443
    to_port   = 443
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

resource "aws_vpc_endpoint" "events" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.events"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.events_endpoint.id,
  ]

  subnet_ids = [
    aws_subnet.privatesubnet1.id,
    aws_subnet.privatesubnet2.id,
    aws_subnet.privatesubnet3.id,
  ]

  private_dns_enabled = true
}

resource "aws_security_group" "events_endpoint" {
  description = "Allow inbound from idp servers"

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    security_groups = [
      aws_security_group.idp.id,
      aws_security_group.app.id,
    ]
  }

  name = "${var.name}-events_endpoint-${var.env_name}"

  tags = {
    Name = "${var.name}-events_endpoint-${var.env_name}"
  }

  vpc_id = aws_vpc.default.id
}

