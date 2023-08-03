### VPC ###
resource "aws_vpc" "default" {
  cidr_block = var.vpc_cidr_block

  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true

  tags = {
    Name = "${var.name}-vpc-${var.env_name}"
  }
}

resource "aws_internet_gateway" "default" {
  tags = {
    Name = "${var.name}-gateway-${var.env_name}"
  }
  vpc_id = aws_vpc.default.id
}

resource "aws_route" "default" {
  route_table_id         = aws_vpc.default.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

### Secondary Cidr Attachment and Subnets from Secondary CIDR range###

resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
  vpc_id     = aws_vpc.default.id
  cidr_block = var.secondary_cidr_block
}

### DB Subnets ###

resource "aws_subnet" "data-services" {
  for_each                = var.az
  availability_zone       = "${var.region}${each.key}"
  cidr_block              = each.value.data-services.ipv4-cidr
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name}-data_services_subnet_${each.key}-${var.env_name}"
  }

  vpc_id = aws_vpc_ipv4_cidr_block_association.secondary_cidr.vpc_id
}

### App Subnets ###

resource "aws_subnet" "app" {
  for_each                = var.az
  availability_zone       = "${var.region}${each.key}"
  cidr_block              = each.value.apps.ipv4-cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-app_subnet_${each.key}-${var.env_name}"
  }

  vpc_id = aws_vpc_ipv4_cidr_block_association.secondary_cidr.vpc_id
}

### DB Subnet Groups ###

resource "aws_db_subnet_group" "aurora" {
  name        = "${var.name}-rds-${var.env_name}"
  description = "RDS Aurora Subnet Group for ${var.env_name} environment"
  subnet_ids  = [for subnet in aws_subnet.data-services : subnet.id]
}

### S3 Gateway endpoint ###

resource "aws_vpc_endpoint" "private-s3" {
  vpc_id          = aws_vpc_ipv4_cidr_block_association.secondary_cidr.vpc_id
  service_name    = "com.amazonaws.${var.region}.s3"
  route_table_ids = [aws_vpc.default.main_route_table_id]
}

### Get vpc flow logs going into cloudwatch ###

resource "aws_flow_log" "flow_log" {
  log_destination = aws_cloudwatch_log_group.flow_log_group.arn
  iam_role_arn    = var.flow_log_iam_role_arn
  vpc_id          = aws_vpc.default.id
  traffic_type    = "ALL"
}

resource "aws_cloudwatch_log_group" "flow_log_group" {
  name = "${var.env_name}_flow_log_group"
}