variable "db1_subnet_cidr_block" { # 172.16.33.32 - 172.16.33.47
  default = "172.16.33.32/28"
}

variable "db2_subnet_cidr_block" { # 172.16.33.48 - 172.16.33.63
  default = "172.16.33.48/28"
}


resource "aws_subnet" "db1" {
  availability_zone       = "${var.region}a"
  cidr_block              = var.db1_subnet_cidr_block
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name}-db1_subnet-${var.env_name} gitlab"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_subnet" "db2" {
  availability_zone       = "${var.region}b"
  cidr_block              = var.db2_subnet_cidr_block
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name}-db2_subnet-${var.env_name} gitlab"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_eip" "nat_a" {
  vpc = true
}

resource "aws_eip" "nat_b" {
  vpc = true
}

resource "aws_eip" "nat_c" {
  vpc = true
}
