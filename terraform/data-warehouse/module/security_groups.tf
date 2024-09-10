# Default Security Group created by VPC resource.
# This security group should not be used by any resources
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.analytics_vpc.id

  tags = {
    Name = "${var.name}-default-${var.env_name}"
  }
}

# Base security group added to all instances, grants default permissions like
# ingress SSH and ICMP.
resource "aws_security_group" "base" {
  name        = "${var.env_name}-base"
  description = "Base security group for rules common to all instances"
  vpc_id      = aws_vpc.analytics_vpc.id

  tags = {
    Name = "${var.env_name}-base"
  }

  ingress {
    description = "Allow ICMP from whole VPC"
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  egress {
    description = "Allow ICMP to whole VPC"
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
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
      aws_security_group.kms_endpoint.id,
      aws_security_group.redshift_data_endpoint.id
    ]
  }

  egress {
    description = "allow egress to api.snapcraft.io"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["91.189.92.0/24"]
  }

  egress {
    description = "allow egress to github to pull necessary repositories"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.github_ipv4_cidr_blocks
  }
}

resource "aws_security_group" "analytics" {
  description = "Allow inbound analytics traffic: allowlisted IPs for SSH"

  name = "${var.name}-analytics-${var.env_name}"

  tags = {
    Name = "${var.name}-analytics_server_security_group-${var.env_name}"
    role = "analytics"
  }

  egress {
    description = "allow outbound to the VPC so that we can get to db/redshift/etc."
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  egress {
    description = "Allow communication to outboundproxies to forward internet requests"
    from_port   = var.proxy_port
    to_port     = var.proxy_port
    protocol    = "tcp"
    cidr_blocks = module.outbound_proxy.proxy_lb_cidr_blocks
  }

  egress {
    description = "allow outbound to RDS/Aurora for database services"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [for zone in local.network_zones : local.network_layout[var.region][var.env_type]["_zones"][zone]["data-services"]["ipv4-cidr"]]
  }

  egress {
    description = "allow communication with Nessus Vulnerability Scanning Server"
    from_port   = 8834
    to_port     = 8834
    protocol    = "tcp"
    cidr_blocks = [var.nessusserver_ip]
  }

  ingress {
    description = "Accept traffic from the ALBs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [
      aws_security_group.analytics_alb.id,
    ]
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.analytics_vpc.id
}

resource "aws_security_group" "db" {
  description = "Allow inbound and outbound postgresql traffic to proper locations"

  egress = []

  ingress {
    description = "Allow inbound connections from analytics hosts"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [
      aws_security_group.analytics.id,
      aws_security_group.migration.id
    ]
  }

  name = "${var.name}-db-${var.env_name}"

  tags = {
    Name = "${var.name}-db_security_group-${var.env_name}"
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.analytics_vpc.id
}

resource "aws_security_group" "ec2_endpoint" {
  name        = "${var.name}-ec2-endpoint-${var.env_name}"
  description = "Allow inbound from all servers"

  egress {
    description = "allow outbound to the whole VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  ingress {
    description = "allow inbound from the whole VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  tags = {
    Name = "${var.name}-ec2-endpoint-${var.env_name}"
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.analytics_vpc.id
}

resource "aws_security_group" "ec2messages_endpoint" {
  name        = "${var.name}-ec2messages-endpoint-${var.env_name}"
  description = "Allow inbound from all servers"

  egress {
    description = "allow outbound to the whole VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  ingress {
    description = "allow inbound from the whole VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  # This rule was created to avoid circular dependencies and allow quarantine hosts to be managed via ssm
  ingress {
    description = "Allows ssm access from private and idp subnets"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  tags = {
    Name = "${var.name}-ec2messages-endpoint-${var.env_name}"
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.analytics_vpc.id
}

resource "aws_security_group" "logs_endpoint" {
  name        = "${var.name}-logs-endpoint-${var.env_name}"
  description = "Allow inbound from all servers"

  egress {
    description = "allow outbound to the whole VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  ingress {
    description = "allow inbound from the whole VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  # This rule was created to avoid circular dependencies and allow quarantine hosts to be managed via ssm
  ingress {
    description = "Allows logging of ssm access from private and idp subnets"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  tags = {
    Name = "${var.name}-logs-endpoint-${var.env_name}"
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.analytics_vpc.id
}

resource "aws_security_group" "monitoring_endpoint" {
  name        = "${var.name}-monitoring-endpoint-${var.env_name}"
  description = "Allow inbound from all servers"

  egress {
    description = "Allow outbound to the whole VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  ingress {
    description = "Allow inbound from the whole VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  tags = {
    Name = "${var.name}-monitoring-endpoint-${var.env_name}"
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.analytics_vpc.id
}

resource "aws_security_group" "secretsmanager_endpoint" {
  name        = "${var.name}-secretsmanager-endpoint-${var.env_name}"
  description = "Allow inbound from all servers"

  egress {
    description = "Allow outbound to the whole VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  ingress {
    description = "Allow inbound from the whole VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  tags = {
    Name = "${var.name}-secretsmanager-endpoint-${var.env_name}"
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.analytics_vpc.id
}

resource "aws_security_group" "sns_endpoint" {
  name        = "${var.name}-sns-endpoint-${var.env_name}"
  description = "Allow inbound from all servers"

  egress {
    description = "Allow outbound to the whole VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  ingress {
    description = "Allow inbound from the whole VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  tags = {
    Name = "${var.name}-sns-endpoint-${var.env_name}"
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.analytics_vpc.id
}

resource "aws_security_group" "smtp_endpoint" {
  name        = "${var.name}-smtp-endpoint-${var.env_name}"
  description = "Allow inbound from all servers"

  # allow outbound to the VPC
  egress {
    description = "Allow outbound to the whole VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  ingress {
    description = "Allow inbound from the whole VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  ingress {
    description = "Allow inbound from the whole VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  tags = {
    Name = "${var.name}-smtp-endpoint-${var.env_name}"
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.analytics_vpc.id
}

resource "aws_security_group" "sts_endpoint" {
  name        = "${var.name}-sts-endpoint-${var.env_name}"
  description = "Allow inbound from all servers"

  # allow outbound to the VPC
  egress {
    description = "Allow outbound to the whole VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  ingress {
    description = "Allow inbound from the whole VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  ingress {
    description = "Allow inbound from the whole VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  tags = {
    Name = "${var.name}-sts-endpoint-${var.env_name}"
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.analytics_vpc.id
}

resource "aws_security_group" "events_endpoint" {
  name        = "${var.name}-events-endpoint-${var.env_name}"
  description = "Allow inbound from all servers"

  egress {
    description = "allow outbound to the whole VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  ingress {
    description = "allow inbound from the whole VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  ingress {
    description = "Allow inbound from the whole VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  tags = {
    Name = "${var.name}-events-endpoint-${var.env_name}"
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.analytics_vpc.id
}

resource "aws_security_group" "redshift_data_endpoint" {
  name        = "${var.name}-redshift-data-endpoint-${var.env_name}"
  description = "Allow inbound from all servers"

  egress {
    description = "allow outbound to the whole VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  ingress {
    description = "Allow inbound from the whole VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  tags = {
    Name = "${var.name}-redshift-data-endpoint-${var.env_name}"
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.analytics_vpc.id
}

resource "aws_security_group" "ssm_endpoint" {
  name        = "${var.name}-ssm-endpoint-${var.env_name}"
  description = "Allow inbound from all servers"

  egress {
    description = "allow outbound to the whole VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  ingress {
    description = "allow inbound from the whole VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  # This rule was created to avoid circular dependencies and allow quarantine hosts to be managed via ssm
  ingress {
    description = "allow ssm access from private and idp subnets"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  tags = {
    Name = "${var.name}-ssm-endpoint-${var.env_name}"
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.analytics_vpc.id
}


resource "aws_security_group" "ssmmessages_endpoint" {
  name        = "${var.name}-ssmmessages-endpoint-${var.env_name}"
  description = "Allow inbound from all servers"

  egress {
    description = "allow outbound to the whole VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  ingress {
    description = "allow inbound from the whole VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  # This rule was created to avoid circular dependencies and allow quarantine hosts to be managed via ssm
  ingress {
    description = "allow ssm access from private and idp subnets"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  tags = {
    Name = "${var.name}-ssmmessages-endpoint-${var.env_name}"
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.analytics_vpc.id
}

resource "aws_security_group" "kms_endpoint" {
  name        = "${var.name}-kms-endpoint-${var.env_name}"
  description = "Allow inbound from all servers"

  egress {
    description = "allow outbound to the whole VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  ingress {
    description = "allow inbound from the whole VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  ingress {
    description = "Allow inbound from the whole VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  tags = {
    Name = "${var.name}-kms-endpoint-${var.env_name}"
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.analytics_vpc.id
}

resource "aws_security_group" "analytics_alb" {
  name        = "${var.env_name}-analytics-alb"
  description = "Allow inbound from the internet"
  vpc_id      = aws_vpc.analytics_vpc.id
}

resource "aws_security_group_rule" "analytics_lb_vpc_egress" {
  security_group_id = aws_security_group.analytics_alb.id
  type              = "egress"
  description       = "Allow outbound to the VPC"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.analytics_vpc.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
}


resource "aws_security_group" "rds_endpoint" {
  name        = "${var.name}-rds-endpoint-${var.env_name}"
  description = "Allow inbound from all servers"

  # allow outbound to the VPC
  egress {
    description = "allow outbound to the whole VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  ingress {
    description = "allow inbound from the whole VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.analytics_vpc.cidr_block,
      aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
    ]
  }

  tags = {
    Name = "${var.name}-rds-endpoint-${var.env_name}"
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.analytics_vpc.id
}

resource "aws_security_group" "redshift" {
  name        = "${var.name}-redshift-security-group-${var.env_name}"
  description = "allow GSA to get to redshift"
  vpc_id      = aws_vpc.analytics_vpc.id

  ingress {
    description = "Allow Analytics Hosts into redshift"
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    security_groups = [
      aws_security_group.analytics.id,
      aws_security_group.migration.id
    ]
  }

  egress {
    description = "allow redshift to reach s3 endpoints for copying"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    prefix_list_ids = [
      aws_vpc_endpoint.private-s3.prefix_list_id,
    ]
  }

  tags = {
    Name = "${var.name}-redshift-${var.env_name}"
  }
}

resource "aws_security_group" "migration" {
  name = "${var.env_name}-migration"

  tags = {
    Name = "${var.env_name}-migration"
    role = "migration"
  }

  vpc_id      = aws_vpc.analytics_vpc.id
  description = "Security group for migration server role"

  # TODO: limit this to what is actually needed
  # allow outbound to the VPC so that we can get to db/redis/logstash/etc.
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  # github
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.github_ipv4_cidr_blocks
  }

  # need 8834 to comm with Nessus Server
  egress {
    from_port   = 8834
    to_port     = 8834
    protocol    = "tcp"
    cidr_blocks = [var.nessusserver_ip]
  }

  #s3 gateway
  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.private-s3.prefix_list_id]
  }

  # need 8834 to comm with Nessus Server
  ingress {
    from_port   = 8834
    to_port     = 8834
    protocol    = "tcp"
    cidr_blocks = [var.nessusserver_ip]
  }
}
