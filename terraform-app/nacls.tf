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

  # allow ntp (if only NACLs let us specify source ports)
  egress {
    from_port = 123
    to_port = 123
    protocol = "udp"
    cidr_block = "0.0.0.0/0"
    rule_no = 20
    action = "allow"
  }
  ingress {
    from_port = 0
    to_port = 65535
    protocol = "udp"
    rule_no = 5
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

  # ssh in from jenkins
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_block = "${var.admin_subnet_cidr_block}"
    rule_no = 50
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

  # allow ntp (if only NACLs let us specify source ports)
  egress {
    from_port = 123
    to_port = 123
    protocol = "udp"
    cidr_block = "0.0.0.0/0"
    rule_no = 20
    action = "allow"
  }
  ingress {
    from_port = 0
    to_port = 65535
    protocol = "udp"
    rule_no = 5
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

  # ssh in from jenkins
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_block = "${var.admin_subnet_cidr_block}"
    rule_no = 25
    action = "allow"
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
  tags {
    client = "${var.client}"
    Name = "${var.name}-chef_network_acl-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
  subnet_ids = ["${aws_subnet.chef.id}"]
}

# -- begin chef rules --
resource "aws_network_acl_rule" "chef-egress-tcp-all" {
  network_acl_id = "${aws_network_acl.chef.id}"

  # allow outbound so it can get packages/git/etc.
  egress = true
  from_port = 0
  to_port = 65535
  protocol = "tcp"
  rule_number = 10
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "chef-egress-ntp" {
  network_acl_id = "${aws_network_acl.chef.id}"

  # allow ntp (if only NACLs let us specify source ports)
  egress = true
  from_port = 123
  to_port = 123
  protocol = "udp"
  cidr_block = "0.0.0.0/0"
  rule_number = 20
  rule_action = "allow"
}

resource "aws_network_acl_rule" "chef-ingress-udp-all" {
  network_acl_id = "${aws_network_acl.chef.id}"

  egress = false
  from_port = 0
  to_port = 65535
  protocol = "udp"
  rule_number = 5
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "chef-ingress-tcp-high" {
  network_acl_id = "${aws_network_acl.chef.id}"

  # allow traffic back in from when hosts here initiate connections
  # to the internet for packages and so on (ephemeral ports)
  egress = false
  from_port = 32768
  to_port = 61000
  protocol = "tcp"
  rule_number = 10
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "chef-ingress-tcp-ssh-jumphost" {
  network_acl_id = "${aws_network_acl.chef.id}"

  # allow ssh from jumphost
  egress = false
  from_port = 22
  to_port = 22
  protocol = "tcp"
  rule_number = 30
  rule_action = "allow"
  cidr_block = "${var.jumphost_subnet_cidr_block}"
}

resource "aws_network_acl_rule" "chef-ingress-tcp-ssh-jenkins" {
  network_acl_id = "${aws_network_acl.chef.id}"

  # ssh in from jenkins
  egress = false
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_block = "${var.admin_subnet_cidr_block}"
    rule_number = 35
    rule_action = "allow"
}

resource "aws_network_acl_rule" "chef-ingress-tcp-443" {
  network_acl_id = "${aws_network_acl.chef.id}"

  # allow everybody in the VPC to chef
  egress = false
  from_port = 443
  to_port = 443
  protocol = "tcp"
  rule_number = 40
  rule_action = "allow"
  cidr_block = "${var.vpc_cidr_block}"
}

# This gets locked down with iptables after we bootstrap the env.
# XXX we will someday figure out how to bootstrap the jumphost first
# so that this can go away.
#
# Allow SSH
resource "aws_network_acl_rule" "chef-ingress-cidr" {
  network_acl_id = "${aws_network_acl.chef.id}"

  # iterate over CIDR blocks
  count = "${length(var.app_sg_ssh_cidr_blocks)}"
  rule_number = "${20 + count.index}"
  egress = false
  protocol = "tcp"
  from_port = 22
  to_port = 22
  cidr_block = "${element(var.app_sg_ssh_cidr_blocks, count.index)}"
  rule_action = "allow"
}
# -- end chef rules --

resource "aws_network_acl" "jumphost" {
  tags {
    client = "${var.client}"
    Name = "${var.name}-jumphost_network_acl-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
  subnet_ids = ["${aws_subnet.jumphost.id}"]
}

# -- begin jumphost rules --
resource "aws_network_acl_rule" "jumphost-egress-tcp-all" {
  network_acl_id = "${aws_network_acl.jumphost.id}"

  # allow us to get out to get packages/gems/git/etc
  egress = true
  from_port = 0
  to_port = 65535
  protocol = "tcp"
  rule_number = 10
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "jumphost-egress-ntp" {
  network_acl_id = "${aws_network_acl.jumphost.id}"

  # allow ntp (if only NACLs let us specify source ports)
  egress = true
  from_port = 123
  to_port = 123
  protocol = "udp"
  cidr_block = "0.0.0.0/0"
  rule_number = 20
  rule_action = "allow"
}

resource "aws_network_acl_rule" "jumphost-egress-dns" {
  network_acl_id = "${aws_network_acl.jumphost.id}"

  # allow dns to stuff (needed for ACME cert gen)
  egress = true
  from_port = 53
  to_port = 53
  protocol = "udp"
  cidr_block = "0.0.0.0/0"
  rule_number = 25
  rule_action = "allow"
}
resource "aws_network_acl_rule" "jumphost-ingress-udp-all" {
  network_acl_id = "${aws_network_acl.jumphost.id}"
  egress = false
  from_port = 0
  to_port = 65535
  protocol = "udp"
  rule_number = 5
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "jumphost-ingress-tcp-high" {
  network_acl_id = "${aws_network_acl.jumphost.id}"

  # allow traffic back in from when hosts here initiate connections
  # to the internet for packages and so on (ephemeral ports)
  egress = false
  from_port = 32768
  to_port = 61000
  protocol = "tcp"
  rule_number = 10
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "jumphost-ingress-tcp-ssh" {
  network_acl_id = "${aws_network_acl.jumphost.id}"

  # ssh in from jenkins
  egress = false
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_block = "${var.admin_subnet_cidr_block}"
  rule_number = 30
  rule_action = "allow"
}

# Allow SSH from app_sg_ssh_cidr_blocks
resource "aws_network_acl_rule" "jumphost-ingress-cidr" {
  network_acl_id = "${aws_network_acl.jumphost.id}"
  # iterate over CIDR blocks
  count = "${length(var.app_sg_ssh_cidr_blocks)}"
  rule_number = "${20 + count.index}"
  egress = false
  protocol = "tcp"
  from_port = 22
  to_port = 22
  cidr_block = "${element(var.app_sg_ssh_cidr_blocks, count.index)}"
  rule_action = "allow"
}
# -- end jumphost rules --


resource "aws_network_acl" "idp" {
  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    rule_no = 10
    action = "allow"
    cidr_block = "0.0.0.0/0"
  }

  # allow ntp (if only NACLs let us specify source ports)
  egress {
    from_port = 123
    to_port = 123
    protocol = "udp"
    cidr_block = "0.0.0.0/0"
    rule_no = 20
    action = "allow"
  }
  ingress {
    from_port = 0
    to_port = 65535
    protocol = "udp"
    rule_no = 5
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

  # ssh in from jenkins
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_block = "${var.admin_subnet_cidr_block}"
    rule_no = 50
    action = "allow"
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

