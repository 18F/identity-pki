resource "aws_elasticache_subnet_group" "idp" {
  name = "${var.name}-cache-${var.env_name}"
  description = "Redis Subnet Group"
  subnet_ids = ["${aws_subnet.app.id}"]
}

resource "aws_internet_gateway" "default" {
  tags {
    client = "${var.client}"
    Name = "${var.name}-gateway-${var.env_name}"
  }
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_route" "default" {
    route_table_id = "${aws_vpc.default.main_route_table_id}"
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
}

resource "aws_security_group" "default" {
  description = "Allow inbound web traffic and whitelisted IPs for SSH"

  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.app_sg_ssh_cidr_blocks}"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  name = "${var.name}-app-${var.env_name}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-security_group-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_security_group" "cache" {
  description = "Allow inbound and outbound redis traffic with app subnet in vpc"

  egress {
    from_port = 6379
    to_port = 6379
    protocol = "tcp"
    cidr_blocks = ["${var.app_subnet_cidr_block}"]
  }

  ingress {
    from_port = 6379
    to_port = 6379
    protocol = "tcp"
    cidr_blocks = ["${var.app_subnet_cidr_block}"]
  }

  name = "${var.name}-cache-${var.env_name}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-security_group_cache-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_security_group" "db" {
  description = "Allow inbound and outbound postgresql traffic with app subnet in vpc"

  egress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = ["${var.app_subnet_cidr_block}"]
  }

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = ["${var.app_subnet_cidr_block}"]
  }

  name = "${var.name}-db-${var.env_name}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-security_group_db-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "app" {
  availability_zone = "${var.region}a"
  cidr_block = "${var.app_subnet_cidr_block}"
  map_public_ip_on_launch = true

  tags {
    client = "${var.client}"
    Name = "${var.name}-subnet-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "app2" {
  availability_zone = "${var.region}b"
  cidr_block = "${var.app2_subnet_cidr_block}"
  map_public_ip_on_launch = true

  tags {
    client = "${var.client}"
    Name = "${var.name}-subnet-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "db1" {
  availability_zone = "${var.region}a"
  cidr_block = "${var.db1_subnet_cidr_block}"
  map_public_ip_on_launch = false

  tags {
    client = "${var.client}"
    Name = "${var.name}-subnet_db-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "db2" {
  availability_zone = "${var.region}b"
  cidr_block = "${var.db2_subnet_cidr_block}"
  map_public_ip_on_launch = false

  tags {
    client = "${var.client}"
    Name = "${var.name}-subnet_db2-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_vpc" "default" {
  cidr_block = "${var.vpc_cidr_block}"
 # main_route_table_id = "${aws_route_table.default.id}"

  tags {
   client = "${var.client}"
   Name = "${var.name}-vpc-${var.env_name}"
  }
}
