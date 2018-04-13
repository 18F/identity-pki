resource "aws_network_acl" "app" {

  tags {
    client = "${var.client}"
    Name = "${var.name}-app_network_acl-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
  subnet_ids = ["${aws_subnet.app.id}"]
}

# Uses up to rule number 25 + number of ssh_cidr_blocks
module "app-base-nacl-rules" {
  source = "../terraform-modules/base_nacl_rules"
  network_acl_id = "${aws_network_acl.app.id}"
  ssh_cidr_blocks = [
      # Jumphost
      "${var.jumphost_subnet_cidr_block}",
      "${var.jumphost1_subnet_cidr_block}",
      "${var.jumphost2_subnet_cidr_block}",
      # Jenkins
      "${var.admin_subnet_cidr_block}",
      # CI VPC
      "${var.ci_sg_ssh_cidr_blocks}"
  ]
}

# this is only used in lower environments, and it needs to be open to partners
resource "aws_network_acl_rule" "app-ingress-http" {
  network_acl_id = "${aws_network_acl.app.id}"
  egress = false
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_block = "0.0.0.0/0"
  rule_number = 40
  rule_action = "allow"
}

# this is only used in lower environments, and it needs to be open to partners
resource "aws_network_acl_rule" "app-ingress-https" {
  network_acl_id = "${aws_network_acl.app.id}"
  egress = false
  from_port = 443
  to_port = 443
  protocol = "tcp"
  cidr_block = "0.0.0.0/0"
  rule_number = 45
  rule_action = "allow"
}

resource "aws_network_acl" "db" {

  tags {
    client = "${var.client}"
    Name = "${var.name}-db_network_acl-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
  subnet_ids = ["${aws_subnet.db1.id}","${aws_subnet.db2.id}"]
}

# allow ephemeral ports out
resource "aws_network_acl_rule" "db-egress-ephemeral" {
  network_acl_id = "${aws_network_acl.db.id}"
  egress = true
  from_port = 32768
  to_port = 61000
  protocol = "tcp"
  rule_number = 5
  rule_action = "allow"
  cidr_block = "${var.vpc_cidr_block}"
}

# let redis in
resource "aws_network_acl_rule" "db-ingress-redis" {
  network_acl_id = "${aws_network_acl.db.id}"
  egress = false
  from_port = 6379
  to_port = 6379
  protocol = "tcp"
  rule_number = 10
  rule_action = "allow"
  cidr_block = "${var.vpc_cidr_block}"
}

# let postgres in
resource "aws_network_acl_rule" "db-ingress-postgres" {
  network_acl_id = "${aws_network_acl.db.id}"
  egress = false
  from_port = 5432
  to_port = 5432
  protocol = "tcp"
  rule_number = 15
  rule_action = "allow"
  cidr_block = "${var.vpc_cidr_block}"
}

# ---------------- end db rules ---------------

resource "aws_network_acl" "admin" {

  tags {
    client = "${var.client}"
    Name = "${var.name}-admin_network_acl-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
  subnet_ids = ["${aws_subnet.admin.id}"]
}

# Uses up to rule number 25 + number of ssh_cidr_blocks
module "admin-base-nacl-rules" {
  source = "../terraform-modules/base_nacl_rules"
  network_acl_id = "${aws_network_acl.admin.id}"
  ssh_cidr_blocks = [
      # Jumphost
      "${var.jumphost_subnet_cidr_block}",
      "${var.jumphost1_subnet_cidr_block}",
      "${var.jumphost2_subnet_cidr_block}",
      # Jenkins
      "${var.admin_subnet_cidr_block}",
      # CI VPC
      "${var.ci_sg_ssh_cidr_blocks}"
  ]
}

# need to allow filebeat to get to logstash
resource "aws_network_acl_rule" "admin-ingress-tcp-logstash" {
  network_acl_id = "${aws_network_acl.admin.id}"
  egress = false
  from_port = 5044
  to_port = 5044
  protocol = "tcp"
  rule_number = 40
  rule_action = "allow"
  cidr_block = "${var.vpc_cidr_block}"
}

# need so that jumphost can get to elk/jenkins
resource "aws_network_acl_rule" "admin-ingress-tcp-elk-jenkins-web" {
  network_acl_id = "${aws_network_acl.admin.id}"
  egress = false
  from_port = 8443
  to_port = 8443
  protocol = "tcp"
  rule_number = 45
  rule_action = "allow"
  cidr_block = "${var.jumphost_subnet_cidr_block}"
}
resource "aws_network_acl_rule" "admin-ingress-tcp-elk-jenkins-web1" {
  network_acl_id = "${aws_network_acl.admin.id}"
  egress = false
  from_port = 8443
  to_port = 8443
  protocol = "tcp"
  rule_number = 46
  rule_action = "allow"
  cidr_block = "${var.jumphost1_subnet_cidr_block}"
}
resource "aws_network_acl_rule" "admin-ingress-tcp-elk-jenkins-web2" {
  network_acl_id = "${aws_network_acl.admin.id}"
  egress = false
  from_port = 8443
  to_port = 8443
  protocol = "tcp"
  rule_number = 47
  rule_action = "allow"
  cidr_block = "${var.jumphost2_subnet_cidr_block}"
}

# Might need this so elk can get to elasticsearch.
resource "aws_network_acl_rule" "admin-ingress-tcp-elasticsearch" {
  network_acl_id = "${aws_network_acl.admin.id}"
  egress = false
  from_port = 9200
  to_port = 9300
  protocol = "tcp"
  rule_number = 50
  rule_action = "allow"
  cidr_block = "${var.admin_subnet_cidr_block}"
}

# Need this to talk to elasticsearch subnets
resource "aws_network_acl_rule" "admin-ingress-tcp-elasticsearch-subnets" {
  count = "${length(var.availability_zones)}"
  network_acl_id = "${aws_network_acl.admin.id}"
  egress = false
  from_port = 9200
  to_port = 9300
  protocol = "tcp"
  rule_number = "${55 + count.index}"
  rule_action = "allow"
  cidr_block = "${element(aws_subnet.elasticsearch.*.cidr_block, count.index)}"
}

resource "aws_network_acl" "chef" {
  tags {
    client = "${var.client}"
    Name = "${var.name}-chef_network_acl-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
  subnet_ids = ["${aws_subnet.chef.id}"]
}

# Uses up to rule number 25 + number of ssh_cidr_blocks
module "chef-base-nacl-rules" {
  source = "../terraform-modules/base_nacl_rules"
  network_acl_id = "${aws_network_acl.chef.id}"
  ssh_cidr_blocks = [
      # Jumphost
      "${var.jumphost_subnet_cidr_block}",
      "${var.jumphost1_subnet_cidr_block}",
      "${var.jumphost2_subnet_cidr_block}",
      # Jenkins
      "${var.admin_subnet_cidr_block}",
      # CI VPC
      "${var.ci_sg_ssh_cidr_blocks}",
      # External Admins
      #
      # This gets locked down with iptables after we bootstrap the env.
      # XXX we will someday figure out how to bootstrap the jumphost first
      # so that this can go away.
      "${var.app_sg_ssh_cidr_blocks}"
  ]
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

resource "aws_network_acl" "jumphost" {
  tags {
    client = "${var.client}"
    Name = "${var.name}-jumphost_network_acl-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
  subnet_ids = [
    "${aws_subnet.jumphost.id}",
    "${aws_subnet.jumphost1.id}",
    "${aws_subnet.jumphost2.id}"
  ]
}

# Uses up to rule number 25 + number of ssh_cidr_blocks
module "jumphost-base-nacl-rules" {
  source = "../terraform-modules/base_nacl_rules"
  network_acl_id = "${aws_network_acl.jumphost.id}"
  ssh_cidr_blocks = [
      # Jumphost (self) ELB
      "${var.jumphost_subnet_cidr_block}",
      "${var.jumphost1_subnet_cidr_block}",
      "${var.jumphost2_subnet_cidr_block}",
      # External Admins
      "${var.app_sg_ssh_cidr_blocks}",
      # Jenkins
      "${var.admin_subnet_cidr_block}",
      # CI VPC
      "${var.ci_sg_ssh_cidr_blocks}"
  ]
}

resource "aws_network_acl_rule" "jumphost-elb-healthcheck1" {
  network_acl_id = "${aws_network_acl.jumphost.id}"
  egress = false
  from_port = 26
  to_port = 26
  protocol = "tcp"
  cidr_block = "${var.jumphost1_subnet_cidr_block}"
  rule_number = 50
  rule_action = "allow"
}

resource "aws_network_acl_rule" "jumphost-elb-healthcheck2" {
  network_acl_id = "${aws_network_acl.jumphost.id}"
  egress = false
  from_port = 26
  to_port = 26
  protocol = "tcp"
  cidr_block = "${var.jumphost2_subnet_cidr_block}"
  rule_number = 51
  rule_action = "allow"
}

resource "aws_network_acl" "idp" {

  tags {
    client = "${var.client}"
    Name = "${var.name}-idp_network_acl-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
  subnet_ids = ["${aws_subnet.idp1.id}","${aws_subnet.idp2.id}"]
}

# Uses up to rule number 25 + number of ssh_cidr_blocks
module "idp-base-nacl-rules" {
  source = "../terraform-modules/base_nacl_rules"
  network_acl_id = "${aws_network_acl.idp.id}"
  ssh_cidr_blocks = [
      # Jumphost
      "${var.jumphost_subnet_cidr_block}",
      "${var.jumphost1_subnet_cidr_block}",
      "${var.jumphost2_subnet_cidr_block}",
      # Jenkins
      "${var.admin_subnet_cidr_block}",
      # CI VPC
      "${var.ci_sg_ssh_cidr_blocks}"
  ]
}

resource "aws_network_acl_rule" "idp-ingress-http" {
  network_acl_id = "${aws_network_acl.idp.id}"
  egress = false
  from_port = 80
  to_port = 80
  protocol = "tcp"
  rule_number = 40
  rule_action = "allow"
  cidr_block = "${var.vpc_cidr_block}"
}
resource "aws_network_acl_rule" "idp-ingress-https" {
  network_acl_id = "${aws_network_acl.idp.id}"
  egress = false
  from_port = 443
  to_port = 443
  protocol = "tcp"
  rule_number = 45
  rule_action = "allow"
  cidr_block = "${var.vpc_cidr_block}"
}

# ------------- end idp rules --------------------

resource "aws_network_acl" "alb" {
  vpc_id = "${aws_vpc.default.id}"
  subnet_ids = ["${aws_subnet.alb1.id}","${aws_subnet.alb2.id}"]

  tags {
    client = "${var.client}"
    Name = "${var.name}-web_network_acl-${var.env_name}"
  }
}
resource "aws_network_acl_rule" "alb-egress-tcp-all-egress" {
  network_acl_id = "${aws_network_acl.alb.id}"
  egress = true
  from_port = 0
  to_port = 65535
  protocol = "tcp"
  rule_number = 10
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
}
# allow traffic back in from when the ALBs do healthchecks
resource "aws_network_acl_rule" "alb-ingress-tcp-all-internal" {
  network_acl_id = "${aws_network_acl.alb.id}"
  egress = false
  from_port = 0
  to_port = 65535
  protocol = "tcp"
  rule_number = 20
  rule_action = "allow"
  cidr_block = "${var.vpc_cidr_block}"
}
resource "aws_network_acl_rule" "alb-ingress-tcp-http" {
  network_acl_id = "${aws_network_acl.alb.id}"
  egress = false
  from_port = 80
  to_port   = 80
  protocol  = "tcp"
  rule_number = 30
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
}
resource "aws_network_acl_rule" "alb-ingress-tcp-https" {
  network_acl_id = "${aws_network_acl.alb.id}"
  egress = false
  from_port = 443
  to_port   = 443
  protocol  = "tcp"
  rule_number = 40
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
}
