resource "aws_vpc_endpoint" "kms" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.kms"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.kms_endpoint.id,
  ]

  subnet_ids = [for zone in local.network_zones : aws_subnet.endpoints[zone].id]

  private_dns_enabled = true

  tags = {
    Name = "${var.env_name}-gitlab-kms"
  }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.logs_endpoint.id,
  ]

  subnet_ids = [for zone in local.network_zones : aws_subnet.endpoints[zone].id]

  private_dns_enabled = true

  tags = {
    Name = "${var.env_name}-gitlab-logs"
  }
}

resource "aws_vpc_endpoint" "monitoring" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.monitoring"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.monitoring_endpoint.id,
  ]

  subnet_ids = [for zone in local.network_zones : aws_subnet.endpoints[zone].id]

  private_dns_enabled = true

  tags = {
    Name = "${var.env_name}-gitlab-monitoring"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.ssm_endpoint.id,
  ]

  subnet_ids = [for zone in local.network_zones : aws_subnet.endpoints[zone].id]

  private_dns_enabled = true

  tags = {
    Name = "${var.env_name}-gitlab-ssm"
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.ssmmessages_endpoint.id,
  ]

  subnet_ids = [for zone in local.network_zones : aws_subnet.endpoints[zone].id]

  private_dns_enabled = true

  tags = {
    Name = "${var.env_name}-gitlab-ssmmessages"
  }
}

resource "aws_vpc_endpoint" "ec2" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.ec2"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.ec2_endpoint.id,
  ]

  subnet_ids = [for zone in local.network_zones : aws_subnet.endpoints[zone].id]

  private_dns_enabled = true

  tags = {
    Name = "${var.env_name}-gitlab-ec2"
  }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.ec2messages_endpoint.id,
  ]

  subnet_ids = [for zone in local.network_zones : aws_subnet.endpoints[zone].id]

  private_dns_enabled = true

  tags = {
    Name = "${var.env_name}-gitlab-ec2messages"
  }
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.secretsmanager_endpoint.id,
  ]

  subnet_ids = [for zone in local.network_zones : aws_subnet.endpoints[zone].id]

  private_dns_enabled = true

  tags = {
    Name = "${var.env_name}-gitlab-secretsmanager"
  }
}

resource "aws_vpc_endpoint" "sns" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.sns"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.sns_endpoint.id,
  ]

  subnet_ids = [for zone in local.network_zones : aws_subnet.endpoints[zone].id]

  private_dns_enabled = true

  tags = {
    Name = "${var.env_name}-gitlab-sns"
  }
}

resource "aws_vpc_endpoint" "sts" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.sts"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.sts_endpoint.id,
  ]

  subnet_ids = [for zone in local.network_zones : aws_subnet.endpoints[zone].id]

  private_dns_enabled = true

  tags = {
    Name = "${var.env_name}-gitlab-sts"
  }
}

resource "aws_vpc_endpoint" "email-smtp" {
  vpc_id            = aws_vpc.default.id
  service_name      = data.aws_vpc_endpoint_service.email-smtp.service_name
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.smtp_endpoint.id
  ]

  # https://github.com/terraform-aws-modules/terraform-aws-vpc/issues/462
  subnet_ids = data.aws_subnets.smtp_subnets.ids

  private_dns_enabled = true

  tags = {
    Name = "${var.env_name}-gitlab-email-smtp"
  }
}

resource "aws_vpc_endpoint" "private-s3" {
  vpc_id       = aws_vpc.default.id
  service_name = "com.amazonaws.${var.region}.s3"
  route_table_ids = flatten([
    aws_route.default.route_table_id, [
      for route in aws_route_table.private_subnet_route_table : route.id
    ]
  ])
}

resource "aws_vpc_endpoint" "events" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.events"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.events_endpoint.id,
  ]

  subnet_ids = [for zone in local.network_zones : aws_subnet.endpoints[zone].id]

  private_dns_enabled = true

  tags = {
    Name = "${var.env_name}-gitlab-events"
  }
}
