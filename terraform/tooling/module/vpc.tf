resource "aws_vpc" "auto_terraform" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "auto_terraform1" {
  vpc_id     = aws_vpc.auto_terraform.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "auto_terraform1"
  }
}

resource "aws_subnet" "auto_terraform2" {
  vpc_id     = aws_vpc.auto_terraform.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "auto_terraform2"
  }
}

resource "aws_internet_gateway" "auto_terraform" {
  tags = {
    Name = "auto_terraform"
  }
  vpc_id = aws_vpc.auto_terraform.id
}

# resource "aws_route" "default" {
#   route_table_id         = aws_vpc.auto_terraform.main_route_table_id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = aws_internet_gateway.auto_terraform.id
# }

resource "aws_vpc_endpoint" "private-s3" {
  vpc_id          = aws_vpc.auto_terraform.id
  service_name    = "com.amazonaws.${var.region}.s3"
  route_table_ids = [aws_vpc.auto_terraform.main_route_table_id]
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.auto_terraform.id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.logs.id]
  subnet_ids          = [aws_subnet.auto_terraform1.id, aws_subnet.auto_terraform2.id]
  private_dns_enabled = true
}

resource "aws_security_group" "logs" {
  name        = "auto_terraform_logs"
  description = "Allow logging to work"
  vpc_id      = aws_vpc.auto_terraform.id

  ingress {
    description = "allow cloudwatch traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.auto_terraform.cidr_block]
  }

  tags = {
    Name = "auto_terraform_logs"
  }
}

resource "aws_security_group" "auto_terraform" {
  name        = "auto_terraform"
  description = "Allow terraform to work"
  vpc_id      = aws_vpc.auto_terraform.id

  egress {
    description = "allow us to do github"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = data.github_ip_ranges.ips.git
  }

  egress {
    description     = "allow traffic to VPC S3 endpoint so we can get code"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.private-s3.prefix_list_id]
  }

  egress {
    description     = "allow traffic to VPC cloudwatch endpoint"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.logs.id]
  }


  tags = {
    Name = "auto_terraform"
  }
}
