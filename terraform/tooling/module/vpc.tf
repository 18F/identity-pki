# This is where all the VPC and networking stuff is set up for the codebuild/pipeline
# stuff to use.
#

resource "aws_vpc" "auto_terraform" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "auto_terraform"
  }
}

# resources in the private subnet where auto_tf stuff runs
resource "aws_subnet" "auto_terraform_private_a" {
  vpc_id     = aws_vpc.auto_terraform.id
  cidr_block = var.auto_tf_private_subnet_cidr

  tags = {
    Name = "auto_terraform private"
  }
}

resource "aws_route_table" "auto_terraform_private" {
  vpc_id = aws_vpc.auto_terraform.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.auto_terraform.id
  }

  tags = {
    Name = "auto_terraform private"
  }
}

resource "aws_route_table_association" "auto_terraform_private" {
  subnet_id = aws_subnet.auto_terraform_private_a.id
  route_table_id = aws_route_table.auto_terraform_private.id
}


# resources in the public subnet where NAT lives
resource "aws_subnet" "auto_terraform_public_a" {
  vpc_id     = aws_vpc.auto_terraform.id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block = var.auto_tf_public_subnet_cidr

  tags = {
    Name = "auto_terraform public"
  }
}

resource "aws_eip" "nat_gateway" {
  vpc = true
}

resource "aws_nat_gateway" "auto_terraform" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.auto_terraform_public_a.id

  tags = {
    Name = "auto_terraform"
  }
  depends_on = [aws_internet_gateway.auto_terraform]
}

resource "aws_route_table" "auto_terraform_public" {
  vpc_id = aws_vpc.auto_terraform.id
  route {
    cidr_block = "0.0.0.0/0"
    vpc_endpoint_id = data.aws_vpc_endpoint.networkfw.id
  }

  tags = {
    Name = "auto_terraform public"
  }
}

resource "aws_route_table_association" "auto_terraform_public" {
  subnet_id = aws_subnet.auto_terraform_public_a.id
  route_table_id = aws_route_table.auto_terraform_public.id
}


# Internet gateway
resource "aws_internet_gateway" "auto_terraform" {
  vpc_id = aws_vpc.auto_terraform.id

  tags = {
    Name = "auto_terraform"
  }
  depends_on = [aws_vpc.auto_terraform]
}

resource "aws_route_table" "auto_terraform_igw" {
  vpc_id = aws_vpc.auto_terraform.id
  route {
    cidr_block = aws_subnet.auto_terraform_public_a.cidr_block
    vpc_endpoint_id = data.aws_vpc_endpoint.networkfw.id
  }

  tags = {
    Name = "auto_terraform route back to nat gateway"
  }
}

resource "aws_route_table_association" "auto_terraform_igw" {
  gateway_id     = aws_internet_gateway.auto_terraform.id
  route_table_id = aws_route_table.auto_terraform_igw.id
}


# security groups
resource "aws_security_group" "auto_terraform" {
  name        = "auto_terraform"
  description = "Allow terraform to work"
  vpc_id      = aws_vpc.auto_terraform.id

  egress {
    description = "allow us to go out to the internet.  Networkfw will limit where we can go."
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "auto_terraform"
  }
}
