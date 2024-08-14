resource "aws_vpc_endpoint" "kms" {
  vpc_id            = aws_vpc.analytics_vpc.id
  service_name      = "com.amazonaws.${var.region}.kms"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.kms_endpoint.id,
  ]

  subnet_ids = [for zone in local.network_zones : aws_subnet.endpoints[zone].id]

  private_dns_enabled = true

  tags = {
    Name = "${var.env_name}-kms"
  }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id            = aws_vpc.analytics_vpc.id
  service_name      = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.logs_endpoint.id,
  ]

  subnet_ids = [for zone in local.network_zones : aws_subnet.endpoints[zone].id]

  private_dns_enabled = true

  tags = {
    Name = "${var.env_name}-logs"
  }
}

resource "aws_vpc_endpoint" "monitoring" {
  vpc_id            = aws_vpc.analytics_vpc.id
  service_name      = "com.amazonaws.${var.region}.monitoring"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.monitoring_endpoint.id,
  ]

  subnet_ids = [for zone in local.network_zones : aws_subnet.endpoints[zone].id]

  private_dns_enabled = true

  tags = {
    Name = "${var.env_name}-monitoring"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = aws_vpc.analytics_vpc.id
  service_name      = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.ssm_endpoint.id,
  ]

  subnet_ids = [for zone in local.network_zones : aws_subnet.endpoints[zone].id]

  private_dns_enabled = true

  tags = {
    Name = "${var.env_name}-ssm"
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id            = aws_vpc.analytics_vpc.id
  service_name      = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.ssmmessages_endpoint.id,
  ]

  subnet_ids = [for zone in local.network_zones : aws_subnet.endpoints[zone].id]

  private_dns_enabled = true

  tags = {
    Name = "${var.env_name}-ssmmessages"
  }
}

resource "aws_vpc_endpoint" "ec2" {
  vpc_id            = aws_vpc.analytics_vpc.id
  service_name      = "com.amazonaws.${var.region}.ec2"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.ec2_endpoint.id,
  ]

  subnet_ids = [for zone in local.network_zones : aws_subnet.endpoints[zone].id]

  private_dns_enabled = true

  tags = {
    Name = "${var.env_name}-ec2"
  }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id            = aws_vpc.analytics_vpc.id
  service_name      = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.ec2messages_endpoint.id,
  ]

  subnet_ids = [for zone in local.network_zones : aws_subnet.endpoints[zone].id]

  private_dns_enabled = true

  tags = {
    Name = "${var.env_name}-ec2messages"
  }
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id            = aws_vpc.analytics_vpc.id
  service_name      = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.secretsmanager_endpoint.id,
  ]

  subnet_ids = [for zone in local.network_zones : aws_subnet.endpoints[zone].id]

  private_dns_enabled = true

  tags = {
    Name = "${var.env_name}-secretsmanager"
  }
}

resource "aws_vpc_endpoint" "sns" {
  vpc_id            = aws_vpc.analytics_vpc.id
  service_name      = "com.amazonaws.${var.region}.sns"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.sns_endpoint.id,
  ]

  subnet_ids = [for zone in local.network_zones : aws_subnet.endpoints[zone].id]

  private_dns_enabled = true

  tags = {
    Name = "${var.env_name}-sns"
  }
}

resource "aws_vpc_endpoint" "sts" {
  vpc_id            = aws_vpc.analytics_vpc.id
  service_name      = "com.amazonaws.${var.region}.sts"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.sts_endpoint.id,
  ]

  subnet_ids = [for zone in local.network_zones : aws_subnet.endpoints[zone].id]

  private_dns_enabled = true

  tags = {
    Name = "${var.env_name}-sts"
  }
}

resource "aws_vpc_endpoint" "private-s3" {
  vpc_id       = aws_vpc.analytics_vpc.id
  service_name = "com.amazonaws.${var.region}.s3"
  route_table_ids = flatten([
    [for table in aws_route_table.public : table.id]
  ])

  tags = {
    Name = "${var.env_name}-s3"
  }
}

resource "aws_vpc_endpoint" "events" {
  vpc_id            = aws_vpc.analytics_vpc.id
  service_name      = "com.amazonaws.${var.region}.events"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.events_endpoint.id,
  ]

  subnet_ids = [for zone in local.network_zones : aws_subnet.endpoints[zone].id]

  private_dns_enabled = true

  tags = {
    Name = "${var.env_name}-events"
  }
}

resource "aws_vpc_endpoint" "rds" {
  vpc_id            = aws_vpc.analytics_vpc.id
  service_name      = "com.amazonaws.${var.region}.rds"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.rds_endpoint.id,
  ]

  subnet_ids = [for zone in local.network_zones : aws_subnet.endpoints[zone].id]

  private_dns_enabled = true

  tags = {
    Name = "${var.env_name}-rds"
  }
}

resource "aws_vpc_endpoint" "redshift_data" {
  vpc_id            = aws_vpc.analytics_vpc.id
  service_name      = "com.amazonaws.${var.region}.redshift-data"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.redshift_data_endpoint.id
  ]

  subnet_ids = [for zone in local.network_zones : aws_subnet.endpoints[zone].id]

  private_dns_enabled = true

  tags = {
    Name = "${var.env_name}-redshift-data"
  }
}
