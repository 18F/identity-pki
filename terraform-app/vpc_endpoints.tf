resource "aws_security_group" "kms_endpoint" {
  description = "Allow inbound from idp servers"

  # allow outbound to the VPC
  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["${var.vpc_cidr_block}"]
  }

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    security_groups = [
        "${aws_security_group.idp.id}",
    ]
  }

  name = "${var.name}-kms_endpoint-${var.env_name}"

  tags {
    Name = "${var.name}-kms_endpoint-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_security_group" "ssm_endpoint" {
  description = "Allow inbound from all servers"

  # allow outbound to the VPC
  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["${var.vpc_cidr_block}"]
  }

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    security_groups = [
        "${aws_security_group.idp.id}",
        "${aws_security_group.app.id}",
        "${aws_security_group.obproxy.id}",
        "${aws_security_group.jumphost.id}",
        "${aws_security_group.elk.id}",
        "${aws_security_group.pivcac.id}",
    ]
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_security_group" "ec2_endpoint" {
  description = "Allow inbound from all servers"

  # allow outbound to the VPC
  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["${var.vpc_cidr_block}"]
  }

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    security_groups = [
        "${aws_security_group.idp.id}",
        "${aws_security_group.app.id}",
        "${aws_security_group.obproxy.id}",
        "${aws_security_group.jumphost.id}",
        "${aws_security_group.elk.id}",
        "${aws_security_group.pivcac.id}",
    ]
  }

  name = "${var.name}-ec2_endpoint-${var.env_name}"

  tags {
    Name = "${var.name}-ec2_endpoint-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_security_group" "ec2messages_endpoint" {
  description = "Allow inbound from all servers"

  # allow outbound to the VPC
  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["${var.vpc_cidr_block}"]
  }

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    security_groups = [
        "${aws_security_group.idp.id}",
        "${aws_security_group.app.id}",
        "${aws_security_group.obproxy.id}",
        "${aws_security_group.jumphost.id}",
        "${aws_security_group.elk.id}",
        "${aws_security_group.pivcac.id}",
    ]
  }

  name = "${var.name}-ec2messages_endpoint-${var.env_name}"

  tags {
    Name = "${var.name}-ec2messages_endpoint-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_security_group" "logs_endpoint" {
  description = "Allow inbound from all servers"

  # allow outbound to the VPC
  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["${var.vpc_cidr_block}"]
  }

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    security_groups = [
        "${aws_security_group.idp.id}",
        "${aws_security_group.app.id}",
        "${aws_security_group.obproxy.id}",
        "${aws_security_group.jumphost.id}",
        "${aws_security_group.elk.id}",
        "${aws_security_group.pivcac.id}",
    ]
  }

  name = "${var.name}-logs_endpoint-${var.env_name}"

  tags {
    Name = "${var.name}-logs_endpoint-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_security_group" "secretsmanager_endpoint" {
  description = "Allow inbound from all servers"

  # allow outbound to the VPC
  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["${var.vpc_cidr_block}"]
  }

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    security_groups = [
        "${aws_security_group.idp.id}",
        "${aws_security_group.app.id}",
        "${aws_security_group.obproxy.id}",
        "${aws_security_group.jumphost.id}",
        "${aws_security_group.elk.id}",
        "${aws_security_group.pivcac.id}",
    ]
  }

  name = "${var.name}-secretsmanager_endpoint-${var.env_name}"

  tags {
    Name = "${var.name}-secretsmanager_endpoint-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_vpc_endpoint" "kms" {
  vpc_id = "${aws_vpc.default.id}"
  service_name = "com.amazonaws.${var.region}.kms"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    "${aws_security_group.kms_endpoint.id}"
  ]

  subnet_ids = [
    "${aws_subnet.privatesubnet1.id}",
    "${aws_subnet.privatesubnet2.id}",
    "${aws_subnet.privatesubnet3.id}",
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id = "${aws_vpc.default.id}"
  service_name = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    "${aws_security_group.logs_endpoint.id}",
  ]

  subnet_ids = [
    "${aws_subnet.privatesubnet1.id}",
    "${aws_subnet.privatesubnet2.id}",
    "${aws_subnet.privatesubnet3.id}",
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id = "${aws_vpc.default.id}"
  service_name = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    "${aws_security_group.ssm_endpoint.id}",
  ]

  subnet_ids = [
    "${aws_subnet.privatesubnet1.id}",
    "${aws_subnet.privatesubnet2.id}",
    "${aws_subnet.privatesubnet3.id}",
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ec2" {
  vpc_id = "${aws_vpc.default.id}"
  service_name = "com.amazonaws.${var.region}.ec2"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    "${aws_security_group.ec2_endpoint.id}",
  ]

  subnet_ids = [
    "${aws_subnet.privatesubnet1.id}",
    "${aws_subnet.privatesubnet2.id}",
    "${aws_subnet.privatesubnet3.id}",
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id = "${aws_vpc.default.id}"
  service_name = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    "${aws_security_group.ec2messages_endpoint.id}",
    ]

  subnet_ids = [
    "${aws_subnet.privatesubnet1.id}",
    "${aws_subnet.privatesubnet2.id}",
    "${aws_subnet.privatesubnet3.id}",
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id = "${aws_vpc.default.id}"
  service_name = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    "${aws_security_group.secretsmanager_endpoint.id}",
    ]

  subnet_ids = [
    "${aws_subnet.privatesubnet1.id}",
    "${aws_subnet.privatesubnet2.id}",
    "${aws_subnet.privatesubnet3.id}",
  ]

  private_dns_enabled = true
}
