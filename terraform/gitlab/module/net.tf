data "aws_ip_ranges" "route53" {
  regions  = ["global"]
  services = ["route53"]
}

locals {
  net_ssm_parameter_prefix = "/${var.env_name}/network/"
}

resource "aws_vpc" "default" {
  cidr_block = var.vpc_cidr_block

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name}-vpc-${var.env_name}"
  }
}

resource "aws_ssm_parameter" "net_vpcid" {
  name  = "${local.net_ssm_parameter_prefix}vpc/id"
  type  = "String"
  value = aws_vpc.default.id
}

# When adding a new subnet, be sure to add an association with a network ACL,
# or it will use the default NACL, which causes problems since the default
# network ACL is special and is handled weirdly by AWS and Terraform.
#
# If you don't explicitly give the subnet a NACL, a terraform plan will show an
# attempt to remove the default plan, which can't actually be done, so it will
# continually show that same plan.
#
# See https://www.terraform.io/docs/providers/aws/r/default_network_acl.html

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

resource "aws_subnet" "gitlab1" {
  availability_zone       = "${var.region}a"
  cidr_block              = var.gitlab1_subnet_cidr_block
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-gitlab1_subnet-${var.env_name}"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_subnet" "gitlab2" {
  availability_zone       = "${var.region}b"
  cidr_block              = var.gitlab2_subnet_cidr_block
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-gitlab2_subnet-${var.env_name}"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_subnet" "alb1" {
  availability_zone       = "${var.region}a"
  cidr_block              = var.alb1_subnet_cidr_block
  depends_on              = [aws_internet_gateway.default]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-alb1_subnet-${var.env_name}"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_subnet" "alb2" {
  availability_zone       = "${var.region}b"
  cidr_block              = var.alb2_subnet_cidr_block
  depends_on              = [aws_internet_gateway.default]
  map_public_ip_on_launch = true

  tags = {
    name = "${var.name}-alb2_subnet-${var.env_name}"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_subnet" "alb3" {
  availability_zone       = "${var.region}c"
  cidr_block              = var.alb3_subnet_cidr_block
  depends_on              = [aws_internet_gateway.default]
  map_public_ip_on_launch = true

  tags = {
    name = "${var.name}-alb3_subnet-${var.env_name}"
  }

  vpc_id = aws_vpc.default.id
}

# create NAT subnets and gateways
resource "aws_subnet" "nat_a" {
  availability_zone       = "${var.region}a"
  cidr_block              = var.nat_a_subnet_cidr_block
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name}-nat_a_subnet-${var.env_name}"
    type = "public"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_eip" "nat_a" {
  vpc = true
}

resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.nat_a.id

  tags = {
    Name = "${var.env_name}-nat_a"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.default]
}

resource "aws_route_table" "nat_a" {
  vpc_id = aws_vpc.default.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }

  tags = {
    Name = "${var.env_name} nat_a"
  }
}

resource "aws_route_table_association" "nat_a" {
  subnet_id      = aws_subnet.nat_a.id
  route_table_id = aws_route_table.nat_a.id
}

resource "aws_subnet" "nat_b" {
  availability_zone       = "${var.region}b"
  cidr_block              = var.nat_b_subnet_cidr_block
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name}-nat_b_subnet-${var.env_name}"
    type = "public"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_eip" "nat_b" {
  vpc = true
}

resource "aws_nat_gateway" "nat_b" {
  allocation_id = aws_eip.nat_b.id
  subnet_id     = aws_subnet.nat_b.id

  tags = {
    Name = "${var.env_name}-nat_b"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.default]
}

resource "aws_route_table" "nat_b" {
  vpc_id = aws_vpc.default.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }

  tags = {
    Name = "${var.env_name} nat_b"
  }
}

resource "aws_route_table_association" "nat_b" {
  subnet_id      = aws_subnet.nat_b.id
  route_table_id = aws_route_table.nat_b.id
}

resource "aws_subnet" "nat_c" {
  availability_zone       = "${var.region}c"
  cidr_block              = var.nat_c_subnet_cidr_block
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name}-nat_c_subnet-${var.env_name}"
    type = "public"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_eip" "nat_c" {
  vpc = true
}

resource "aws_nat_gateway" "nat_c" {
  allocation_id = aws_eip.nat_c.id
  subnet_id     = aws_subnet.nat_c.id

  tags = {
    Name = "${var.env_name}-nat_c"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.default]
}

resource "aws_route_table" "nat_c" {
  vpc_id = aws_vpc.default.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }

  tags = {
    Name = "${var.env_name} nat_c"
  }
}

resource "aws_route_table_association" "nat_c" {
  subnet_id      = aws_subnet.nat_c.id
  route_table_id = aws_route_table.nat_c.id
}

# create public and private subnets
resource "aws_subnet" "publicsubnet1" {
  availability_zone       = "${var.region}a"
  cidr_block              = var.public1_subnet_cidr_block
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-public1_subnet-${var.env_name}"
    type = "public"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_route_table" "publicsubnet1" {
  vpc_id = aws_vpc.default.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }

  tags = {
    Name = "${var.env_name}-publicsubnet1"
  }
}

resource "aws_route_table_association" "publicsubnet1" {
  subnet_id      = aws_subnet.publicsubnet1.id
  route_table_id = aws_route_table.publicsubnet1.id
}

resource "aws_subnet" "publicsubnet2" {
  availability_zone       = "${var.region}b"
  cidr_block              = var.public2_subnet_cidr_block
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-public2_subnet-${var.env_name}"
    type = "public"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_route_table" "publicsubnet2" {
  vpc_id = aws_vpc.default.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_b.id
  }

  tags = {
    Name = "${var.env_name}-publicsubnet2"
  }
}

resource "aws_route_table_association" "publicsubnet2" {
  subnet_id      = aws_subnet.publicsubnet2.id
  route_table_id = aws_route_table.publicsubnet2.id
}

resource "aws_subnet" "publicsubnet3" {
  availability_zone       = "${var.region}c"
  cidr_block              = var.public3_subnet_cidr_block
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-public3_subnet-${var.env_name}"
    type = "public"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_route_table" "publicsubnet3" {
  vpc_id = aws_vpc.default.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_c.id
  }

  tags = {
    Name = "${var.env_name}-publicsubnet3"
  }
}

resource "aws_route_table_association" "publicsubnet3" {
  subnet_id      = aws_subnet.publicsubnet3.id
  route_table_id = aws_route_table.publicsubnet3.id
}

resource "aws_subnet" "privatesubnet1" {
  availability_zone       = "${var.region}a"
  cidr_block              = var.private1_subnet_cidr_block
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name}-private1_subnet-${var.env_name}"
    type = "private"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_ssm_parameter" "net_subnet_private1" {
  name  = "${local.net_ssm_parameter_prefix}subnet/private1/id"
  type  = "String"
  value = aws_subnet.privatesubnet1.id
}

resource "aws_subnet" "privatesubnet2" {
  availability_zone       = "${var.region}b"
  cidr_block              = var.private2_subnet_cidr_block
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name}-private2_subnet-${var.env_name}"
    type = "private"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_ssm_parameter" "net_subnet_private2" {
  name  = "${local.net_ssm_parameter_prefix}subnet/private2/id"
  type  = "String"
  value = aws_subnet.privatesubnet2.id
}

resource "aws_subnet" "privatesubnet3" {
  availability_zone       = "${var.region}c"
  cidr_block              = var.private3_subnet_cidr_block
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name}-private3_subnet-${var.env_name}"
    type = "private"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_ssm_parameter" "net_subnet_private3" {
  name  = "${local.net_ssm_parameter_prefix}subnet/private3/id"
  type  = "String"
  value = aws_subnet.privatesubnet3.id
}

resource "aws_elasticache_subnet_group" "gitlab" {
  name        = "${var.name}-gitlab-cache-${var.env_name}"
  description = "Redis Subnet Group"
  subnet_ids  = [aws_subnet.db1.id, aws_subnet.db2.id]
}
