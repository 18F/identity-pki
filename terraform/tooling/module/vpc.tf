resource "aws_vpc" "auto_terraform" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "auto_terraform"
  }
}

resource "aws_subnet" "auto_terraform_private" {
  vpc_id     = aws_vpc.auto_terraform.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "auto_terraform private"
  }
}

resource "aws_subnet" "auto_terraform_public" {
  vpc_id     = aws_vpc.auto_terraform.id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "auto_terraform public"
  }
}

resource "aws_internet_gateway" "auto_terraform" {
  vpc_id = aws_vpc.auto_terraform.id

  tags = {
    Name = "auto_terraform"
  }
}

resource "aws_eip" "nat_gateway" {
  vpc = true
}

resource "aws_nat_gateway" "auto_terraform" {
  depends_on = [aws_internet_gateway.auto_terraform]
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.auto_terraform_public.id

  tags = {
    Name = "auto_terraform"
  }
}

resource "aws_route_table" "auto_terraform_public" {
  vpc_id = aws_vpc.auto_terraform.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.auto_terraform.id
  }
}

resource "aws_route_table_association" "auto_terraform_public" {
  subnet_id = aws_subnet.auto_terraform_public.id
  route_table_id = aws_route_table.auto_terraform_public.id
}

resource "aws_route_table" "auto_terraform_private" {
  vpc_id = aws_vpc.auto_terraform.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.auto_terraform.id
  }
}

resource "aws_route_table_association" "auto_terraform_private" {
  subnet_id = aws_subnet.auto_terraform_private.id
  route_table_id = aws_route_table.auto_terraform_private.id
}

resource "aws_vpc_endpoint" "private-s3" {
  vpc_id          = aws_vpc.auto_terraform.id
  service_name    = "com.amazonaws.${var.region}.s3"
  route_table_ids = [aws_vpc.auto_terraform.main_route_table_id]

  tags = {
    Name = "auto_terraform_s3"
  }
}

resource "aws_vpc_endpoint" "private-dynamodb" {
  vpc_id          = aws_vpc.auto_terraform.id
  service_name    = "com.amazonaws.${var.region}.dynamodb"
  route_table_ids = [aws_vpc.auto_terraform.main_route_table_id]

  tags = {
    Name = "auto_terraform_dynamodb"
  }
}

resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = aws_vpc.auto_terraform.id
  service_name        = "com.amazonaws.${var.region}.ec2"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.allowssl.id]
  subnet_ids          = [aws_subnet.auto_terraform_public.id]
  private_dns_enabled = true

  tags = {
    Name = "auto_terraform_ec2"
  }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.auto_terraform.id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.allowssl.id]
  subnet_ids          = [aws_subnet.auto_terraform_public.id]
  private_dns_enabled = true

  tags = {
    Name = "auto_terraform_logs"
  }
}

data "aws_vpc_endpoint_service" "sts" {
  service      = "sts"
  service_type = "Interface"
}

resource "aws_vpc_endpoint" "sts" {
  vpc_id              = aws_vpc.auto_terraform.id
  service_name        = data.aws_vpc_endpoint_service.sts.service_name
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.allowssl.id]
  subnet_ids          = [aws_subnet.auto_terraform_public.id]
  private_dns_enabled = true

  tags = {
    Name = "auto_terraform_sts"
  }
}

resource "aws_vpc_endpoint" "sns" {
  vpc_id              = aws_vpc.auto_terraform.id
  service_name        = "com.amazonaws.${var.region}.sns"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.allowssl.id]
  subnet_ids          = [aws_subnet.auto_terraform_public.id]
  private_dns_enabled = true

  tags = {
    Name = "auto_terraform_sns"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.auto_terraform.id
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.allowssl.id]
  subnet_ids          = [aws_subnet.auto_terraform_public.id]
  private_dns_enabled = true

  tags = {
    Name = "auto_terraform_ssm"
  }
}

resource "aws_security_group" "allowssl" {
  name        = "auto_terraform_logs"
  description = "Allow logging to work"
  vpc_id      = aws_vpc.auto_terraform.id

  ingress {
    description = "allow ssl traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.auto_terraform.cidr_block]
  }

  egress {
    description = "allow ssl traffic"
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
    description     = "allow traffic to VPC dynamodb endpoint so we can get code"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.private-dynamodb.prefix_list_id]
  }

  egress {
    description     = "allow traffic to VPC interface endpoints"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.allowssl.id]
  }


  tags = {
    Name = "auto_terraform"
  }
}
