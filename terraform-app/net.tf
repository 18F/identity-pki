resource "aws_elasticache_subnet_group" "idp" {
  name = "${var.name}-idp-cache-${var.env_name}"
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

resource "aws_security_group" "jumphost" {
  description = "Allow inbound jumphost traffic: whitelisted IPs for SSH"

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

  name = "${var.name}-jumphost"

  tags {
    client = "${var.client}"
    Name = "${var.name}-jumphost"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_security_group" "chef" {
  description = "Allow inbound chef traffic and whitelisted IPs for SSH"

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
    from_port = 443
    to_port = 443
    protocol = "tcp"
    self = true
    cidr_blocks = [ "${concat(var.app_sg_ssh_cidr_blocks,list(aws_vpc.default.cidr_block))}" ]
  }

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    security_groups = [ "${aws_security_group.jumphost.id}" ]
  }

  name = "${var.name}-chef"

  tags {
    client = "${var.client}"
    Name = "${var.name}-chef"
  }

  vpc_id = "${aws_vpc.default.id}"
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
    self = true
    cidr_blocks = ["${var.app_sg_ssh_cidr_blocks}"]
  }

  ingress {
    from_port = 8443
    to_port = 8443
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

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    security_groups = [ "${aws_security_group.jumphost.id}" ]
  }

  name = "${var.name}-chef"
  name = "${var.name}-app-${var.env_name}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-security_group-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_security_group" "elk" {
  description = "Allow inbound traffic to ELK from whitelisted IPs for SSH and app security group"

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
    self = true
    cidr_blocks = ["${var.app_sg_ssh_cidr_blocks}"]
  }

  ingress {
    from_port = 8443
    to_port = 8443
    protocol = "tcp"
    self = true
    cidr_blocks = ["${var.app_sg_ssh_cidr_blocks}"]
  }

  ingress {
    from_port = 9200
    to_port = 9300
    protocol = "tcp"
    self = true
    cidr_blocks = ["${var.app_sg_ssh_cidr_blocks}"]
  }

  ingress {
    from_port = 5044
    to_port = 5044
    protocol = "tcp"
    self = true
    cidr_blocks = ["${var.app_sg_ssh_cidr_blocks}"]
    security_groups = [ "${aws_security_group.default.id}" ]
  }

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    security_groups = [ "${aws_security_group.jumphost.id}" ]
  }

  name = "${var.name}-chef"
  name = "${var.name}-elk-${var.env_name}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-elk_security_group-${var.env_name}"
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

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    security_groups = [ "${aws_security_group.jumphost.id}" ]
  }

  name = "${var.name}-chef"
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

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    security_groups = [ "${aws_security_group.jumphost.id}" ]
  }

  name = "${var.name}-chef"
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

resource "aws_subnet" "chef" {
  availability_zone = "${var.region}b"
  cidr_block = "${var.chef_subnet_cidr_block}"
  map_public_ip_on_launch = true

  tags {
    client = "${var.client}"
    Name = "${var.name}-subnet_chef-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "jumphost" {
  availability_zone = "${var.region}b"
  cidr_block = "${var.jumphost_subnet_cidr_block}"
  map_public_ip_on_launch = true

  tags {
    client = "${var.client}"
    Name = "${var.name}-subnet_jumphost-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_vpc_endpoint" "private-s3" {
    vpc_id = "${aws_vpc.default.id}"
    service_name = "com.amazonaws.${var.region}.s3"
    route_table_ids = ["${aws_vpc.default.main_route_table_id}"]
}

resource "aws_vpc" "default" {
  cidr_block = "${var.vpc_cidr_block}"
 # main_route_table_id = "${aws_route_table.default.id}"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags {
   client = "${var.client}"
   Name = "${var.name}-vpc-${var.env_name}"
  }
}
