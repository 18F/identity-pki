resource "aws_internet_gateway" "default" {
  tags {
    client = "${var.client}"
    Name = "${var.name}"
  }
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_route53_record" "a_dev" {
  name = "dev-tf.login.gov"
  records = ["${aws_instance.web.public_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "c_idp" {
  name = "idp-dev-tf.login.gov"
  records = ["${aws_route53_record.a_dev.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "c_idv" {
  name = "idv-dev-tf.login.gov"
  records = ["${aws_route53_record.a_dev.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "c_sp" {
  name = "sp-dev-tf.login.gov"
  records = ["${aws_route53_record.a_dev.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.zone_id}"
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

  name = "identity_security_group"

  tags {
    client = "${var.client}"
    Name = "${var.name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_security_group" "db" {
  description = "Allow inbound and outbound postgresql traffic to app subnet in vpc"

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

  name = "identity_db_security_group"

  tags {
    client = "${var.client}"
    Name = "${var.name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "app" {
  availability_zone = "us-east-1a"
  cidr_block = "${var.app_subnet_cidr_block}"
  map_public_ip_on_launch = true

  tags {
    client = "${var.client}"
    Name = "${var.name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "db1" {
  availability_zone = "us-east-1d"
  cidr_block = "${var.db1_subnet_cidr_block}"
  map_public_ip_on_launch = false

  tags {
    client = "${var.client}"
    Name = "${var.name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "db2" {
  availability_zone = "us-east-1b"
  cidr_block = "${var.db2_subnet_cidr_block}"
  map_public_ip_on_launch = false

  tags {
    client = "${var.client}"
    Name = "${var.name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_vpc" "default" {
  cidr_block = "${var.vpc_cidr_block}"
 # main_route_table_id = "${aws_route_table.default.id}"

  tags {
   client = "${var.client}"
   Name = "${var.name}"
  }
}
