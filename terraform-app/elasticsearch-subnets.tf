resource "aws_subnet" "elasticsearch" {
  count = "${length(var.availability_zones)}"
  availability_zone = "${element(var.availability_zones, count.index)}"
  cidr_block = "${cidrsubnet(var.elasticsearch_cidr_block, 2, count.index)}"
  # Set this to false when we use the proxy
  map_public_ip_on_launch = true

  tags {
    client = "${var.client}"
    Name = "${var.name}-elasticsearch_subnet-${var.env_name}-${element(var.availability_zones, count.index)}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_network_acl" "elasticsearch" {

  tags {
    client = "${var.client}"
    Name = "${var.name}-elasticsearch_network_acl-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
  subnet_ids = ["${aws_subnet.elasticsearch.*.id}"]
}

# Uses up to rule number 25 + number of ssh_cidr_blocks
module "elasticsearch-base-nacl-rules" {
  source = "../terraform-modules/base_nacl_rules"
  network_acl_id = "${aws_network_acl.elasticsearch.id}"
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

# Might need this so elk can get to elasticsearch.
resource "aws_network_acl_rule" "elasticsearch-ingress-tcp-admin" {
  network_acl_id = "${aws_network_acl.elasticsearch.id}"
  egress = false
  from_port = 9200
  to_port = 9300
  protocol = "tcp"
  rule_number = 50
  rule_action = "allow"
  cidr_block = "${var.admin_subnet_cidr_block}"
}

# Need this so elasticsearch can talk across subnets
resource "aws_network_acl_rule" "elasticsearch-ingress-tcp-elasticsearch" {
  count = "${length(var.availability_zones)}"
  network_acl_id = "${aws_network_acl.elasticsearch.id}"
  egress = false
  from_port = 9200
  to_port = 9300
  protocol = "tcp"
  rule_number = "${55 + count.index}"
  rule_action = "allow"
  cidr_block = "${element(aws_subnet.elasticsearch.*.cidr_block, count.index)}"
}

# Need this so asg elk can get to elasticsearch
resource "aws_network_acl_rule" "elasticsearch-ingress-tcp-elk" {
  count = "${length(var.availability_zones)}"
  network_acl_id = "${aws_network_acl.elasticsearch.id}"
  egress = false
  from_port = 9200
  to_port = 9300
  protocol = "tcp"
  rule_number = "${60 + count.index}"
  rule_action = "allow"
  cidr_block = "${element(aws_subnet.elk.*.cidr_block, count.index)}"
}
