resource "aws_vpc" "main" {
  cidr_block                       = var.image_build_vpc_cidr
  instance_tenancy                 = "default"
  assign_generated_ipv6_cidr_block = var.assign_generated_ipv6_cidr_block

  enable_dns_hostnames = true

  tags = {
    Name = "${var.name}-${data.aws_region.current.name}-${var.account_name}-imagebuild"
  }
}

# Default Security Group created by VPC resource.
# This security group should not be used by any resources
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-${var.account_name}-${var.region}-default"
  }

}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-${var.account_name}-imagebuild"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = data.aws_eip.main.id
  subnet_id     = aws_subnet.public.id
  tags = {
    Name = "${var.name}-${var.account_name}-imagebuild"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-${var.account_name}-public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-${var.account_name}-private"
  }
}

resource "aws_route" "private_default_ipv4" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

resource "aws_route" "public_default_ipv4" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.image_build_private_cidr

  tags = {
    Name = "${var.name}-${var.account_name}-private"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.image_build_public_cidr

  tags = {
    Name = "${var.name}-${var.account_name}-public"
  }
}

resource "aws_vpc_endpoint" "ec2" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.ec2"
  vpc_endpoint_type = "Interface"

  security_group_ids = [aws_security_group.endpoint.id]

  subnet_ids = [aws_subnet.private.id]

  private_dns_enabled = true

  tags = {
    Name = "${var.name}-${var.account_name}-${var.region}-ec2"
  }
}

resource "aws_security_group" "endpoint" {
  vpc_id      = aws_vpc.main.id
  description = "Associated with AWS Service Endpoints"
  name        = "${var.name}-${var.account_name}-${var.region}-endpoints"

  tags = {
    Name = "${var.name}-${var.account_name}-${var.region}-endpoints"
  }
}

resource "aws_vpc_security_group_ingress_rule" "endpoint_communications" {
  security_group_id = aws_security_group.endpoint.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}
