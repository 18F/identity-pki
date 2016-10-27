resource "aws_internet_gateway" "default" {
  tags {
    client = "${var.client}"
    Name = "${var.name}-chef"
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
    cidr_blocks = ["${concat(
      var.app_sg_ssh_cidr_blocks,
      list(var.app_subnet_cidr_block),
      list(var.app2_subnet_cidr_block)
    )}"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [
      "${concat(var.app_sg_ssh_cidr_blocks,
        list(format("%s/32",data.terraform_remote_state.app-dev.aws_eip_app_public_ip)),
        list(format("%s/32",data.terraform_remote_state.app-dev.aws_instance_worker_public_ip)),
        list(format("%s/32",data.terraform_remote_state.app-pt.aws_eip_app_public_ip)),
        list(format("%s/32",data.terraform_remote_state.app-pt.aws_instance_worker_public_ip)),
        list(format("%s/32",data.terraform_remote_state.app-qa.aws_eip_app_public_ip)),
        list(format("%s/32",data.terraform_remote_state.app-qa.aws_instance_worker_public_ip)),
        list(format("%s/32",data.terraform_remote_state.app-tf.aws_eip_app_public_ip)),
        list(format("%s/32",data.terraform_remote_state.app-tf.aws_instance_worker_public_ip))
      )}"
    ]
  }

  name = "${var.name}-chef"

  tags {
    client = "${var.client}"
    Name = "${var.name}-chef"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "app" {
  availability_zone = "${var.region}a"
  cidr_block = "${var.subnet_cidr_block_chef}"
  map_public_ip_on_launch = true

  tags {
    client = "${var.client}"
    Name = "${var.name}-chef"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_vpc" "default" {
  cidr_block = "${var.vpc_cidr_block_chef}"

  tags {
   client = "${var.client}"
   Name = "${var.name}-chef"
  }
}
