resource "aws_vpc" "auto_terraform" {
  cidr_block = "10.0.0.0/16"
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

resource "aws_security_group" "auto_terraform" {
  name        = "auto_terraform"
  description = "Allow terraform to work"
  vpc_id      = aws_vpc.auto_terraform.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = data.github_ip_ranges.ips.git
  }

  tags = {
    Name = "auto_terraform"
  }
}
