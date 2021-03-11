# We could probably remove these VPC endpoints and just let the
# networkfw handle all this, but VPC endpoints are cheaper than
# going through the internet gateway.

resource "aws_subnet" "auto_terraform_vpcendpoints" {
  vpc_id     = aws_vpc.auto_terraform.id
  cidr_block = var.auto_tf_vpcendpoints_subnet_cidr

  tags = {
    Name = "auto_terraform firewall"
  }
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
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  subnet_ids          = [aws_subnet.auto_terraform_vpcendpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "auto_terraform_ec2"
  }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.auto_terraform.id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  subnet_ids          = [aws_subnet.auto_terraform_vpcendpoints.id]
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
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  subnet_ids          = [aws_subnet.auto_terraform_vpcendpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "auto_terraform_sts"
  }
}

resource "aws_vpc_endpoint" "sns" {
  vpc_id              = aws_vpc.auto_terraform.id
  service_name        = "com.amazonaws.${var.region}.sns"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  subnet_ids          = [aws_subnet.auto_terraform_vpcendpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "auto_terraform_sns"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.auto_terraform.id
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  subnet_ids          = [aws_subnet.auto_terraform_vpcendpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "auto_terraform_ssm"
  }
}

resource "aws_security_group" "vpc_endpoints" {
  name        = "vpc_endpoints"
  description = "Allow auto_terraform to contact vpc endpoints"
  vpc_id      = aws_vpc.auto_terraform.id

  ingress {
    description     = "allow auto_terraform to contact vpc endpoints"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.auto_terraform.id]
  }

  tags = {
    Name = "vpc_endpoints"
  }
}
