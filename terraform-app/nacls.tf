resource "aws_network_acl" "app" {
  count = "${var.apps_enabled == true ? 1 : 0}"

  # allow traffic out to get packages/gems/git
  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_block = "0.0.0.0/0"
    rule_no = 10
    action = "allow"
  }

  # allow traffic back in from when hosts here initiate connections
  # to the internet for packages and so on (ephemeral ports)
  ingress {
    from_port = 32768
    to_port = 61000
    protocol = "tcp"
    rule_no = 10
    action = "allow"
    cidr_block = "0.0.0.0/0"
  }

  # this is only used in lower environments, and it needs to be open to partners
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_block = "0.0.0.0/0"
    rule_no = 20
    action = "allow"
  }

  # this is only used in lower environments, and it needs to be open to partners
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_block = "0.0.0.0/0"
    rule_no = 30
    action = "allow"
  }

  # ssh in from jumphost
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_block = "${var.jumphost_subnet_cidr_block}"
    rule_no = 40
    action = "allow"
  }

  tags {
    client = "${var.client}"
    Name = "${var.name}-app_network_acl-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
  subnet_ids = ["${aws_subnet.app.id}"]
}

resource "aws_network_acl" "db" {
  # allow ephemeral ports out
  egress {
    from_port = 32768
    to_port = 61000
    protocol = "tcp"
    rule_no = 10
    action = "allow"
    cidr_block = "${var.vpc_cidr_block}"
  }

  # let redis in
  ingress {
    from_port = 6379
    to_port = 6379
    protocol = "tcp"
    rule_no = 10
    action = "allow"
    cidr_block = "${var.vpc_cidr_block}"
  }

  # let postgres in
  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    rule_no = 20
    action = "allow"
    cidr_block = "${var.vpc_cidr_block}"
  }

  tags {
    client = "${var.client}"
    Name = "${var.name}-db_network_acl-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
  subnet_ids = ["${aws_subnet.db1.id}","${aws_subnet.db2.id}"]
}

resource "aws_network_acl" "admin" {
  # allow hosts here to go out to get packages/gems/git/etc
  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    rule_no = 10
    action = "allow"
    cidr_block = "0.0.0.0/0"
  }

  # allow traffic back in from when hosts here initiate connections
  # to the internet for packages and so on (ephemeral ports)
  ingress {
    from_port = 32768
    to_port = 61000
    protocol = "tcp"
    rule_no = 10
    action = "allow"
    cidr_block = "0.0.0.0/0"
  }

  # need to allow jumphost ssh access
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    rule_no = 20
    action = "allow"
    cidr_block = "${var.jumphost_subnet_cidr_block}"
  }

  # need to allow filebeat to get to logstash
  ingress {
    from_port = 5044
    to_port = 5044
    protocol = "tcp"
    rule_no = 30
    action = "allow"
    cidr_block = "${var.vpc_cidr_block}"
  }

  # need so that jumphost can get to elk/jenkins
  ingress {
    from_port = 8443
    to_port = 8443
    protocol = "tcp"
    rule_no = 50
    action = "allow"
    cidr_block = "${var.jumphost_subnet_cidr_block}"
  }

  # Might need this so elk can get to elasticsearch.
  ingress {
    from_port = 9200
    to_port = 9300
    protocol = "tcp"
    rule_no = 60
    action = "allow"
    cidr_block = "${var.admin_subnet_cidr_block}"
  }

  tags {
    client = "${var.client}"
    Name = "${var.name}-admin_network_acl-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
  subnet_ids = ["${aws_subnet.admin.id}"]
}


resource "aws_network_acl" "chef" {
  # allow outbound so it can get packages/git/etc.
  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    rule_no = 10
    action = "allow"
    cidr_block = "0.0.0.0/0"
  }

  # allow traffic back in from when hosts here initiate connections
  # to the internet for packages and so on (ephemeral ports)
  ingress {
    from_port = 32768
    to_port = 61000
    protocol = "tcp"
    rule_no = 10
    action = "allow"
    cidr_block = "0.0.0.0/0"
  }

  # This gets locked down with iptables after we bootstrap the env.
  # XXX we will someday figure out how to bootstrap the jumphost first
  # so that this can go away.
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    rule_no = 20
    action = "allow"
    # XXX this is kinda a hack.  These rules don't allow multiple nets.
    # 0 _should_ be the GSA cidr block.
    cidr_block = "${element(var.app_sg_ssh_cidr_blocks,0)}"
  }

  # allow ssh from jumphost
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    rule_no = 30
    action = "allow"
    cidr_block = "${var.jumphost_subnet_cidr_block}"
  }

  # allow everybody in the VPC to chef
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    rule_no = 40
    action = "allow"
    cidr_block = "${var.vpc_cidr_block}"
  }

  tags {
    client = "${var.client}"
    Name = "${var.name}-chef_network_acl-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
  subnet_ids = ["${aws_subnet.chef.id}"]
}


resource "aws_network_acl" "jumphost" {
  # allow us to get out to get packages/gems/git/etc
  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    rule_no = 10
    action = "allow"
    cidr_block = "0.0.0.0/0"
  }

  # allow traffic back in from when hosts here initiate connections
  # to the internet for packages and so on (ephemeral ports)
  ingress {
    from_port = 32768
    to_port = 61000
    protocol = "tcp"
    rule_no = 10
    action = "allow"
    cidr_block = "0.0.0.0/0"
  }

  # allow ssh in from GSA
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    rule_no = 20
    action = "allow"
    # XXX this is kinda a hack.  These rules don't allow multiple nets.
    # 0 _should_ be the GSA cidr block.
    cidr_block = "${element(var.app_sg_ssh_cidr_blocks,0)}"
  }

  tags {
    client = "${var.client}"
    Name = "${var.name}-jumphost_network_acl-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
  subnet_ids = ["${aws_subnet.jumphost.id}"]
}

resource "aws_network_acl" "idp" {
  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    rule_no = 10
    action = "allow"
    cidr_block = "0.0.0.0/0"
  }

  # allow traffic back in from when hosts here initiate connections
  # to the internet for packages and so on (ephemeral ports)
  ingress {
    from_port = 32768
    to_port = 61000
    protocol = "tcp"
    rule_no = 10
    action = "allow"
    cidr_block = "0.0.0.0/0"
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    rule_no = 20
    action = "allow"
    cidr_block = "${var.vpc_cidr_block}"
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    rule_no = 30
    action = "allow"
    cidr_block = "${var.vpc_cidr_block}"
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    rule_no = 40
    action = "allow"
    cidr_block = "${var.jumphost_subnet_cidr_block}"
  }

  tags {
    client = "${var.client}"
    Name = "${var.name}-idp_network_acl-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
  subnet_ids = ["${aws_subnet.idp1.id}","${aws_subnet.idp2.id}"]
}

resource "aws_network_acl" "alb" {
  vpc_id = "${aws_vpc.default.id}"
  subnet_ids = ["${aws_subnet.alb1.id}","${aws_subnet.alb2.id}"]

  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    rule_no = 10
    action = "allow"
    cidr_block = "0.0.0.0/0"
  }

  # allow traffic back in from when the ALBs do healthchecks
  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    rule_no = 10
    action = "allow"
    cidr_block = "${var.vpc_cidr_block}"
  }

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    rule_no = 20
    action = "allow"
    cidr_block = "0.0.0.0/0"
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    rule_no = 30
    action = "allow"
    cidr_block = "0.0.0.0/0"
  }

  tags {
    client = "${var.client}"
    Name = "${var.name}-web_network_acl-${var.env_name}"
  }
}

