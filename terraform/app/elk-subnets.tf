resource "aws_subnet" "elk" {
  count             = length(var.availability_zones)
  availability_zone = element(var.availability_zones, count.index)
  cidr_block        = cidrsubnet(var.elk_cidr_block, 2, count.index)

  # Set this to false when we use the proxy
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-elk_subnet-${var.env_name}-${element(var.availability_zones, count.index)}"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_network_acl" "elk" {
  tags = {
    Name = "${var.env_name}-elk"
  }

  vpc_id     = aws_vpc.default.id
  subnet_ids = aws_subnet.elk.*.id
}

# Uses up to rule number 25 + number of ssh_cidr_blocks
module "elk-base-nacl-rules" {
  source         = "../modules/base_nacl_rules"
  network_acl_id = aws_network_acl.elk.id
  ssh_cidr_blocks = flatten([
    # Jumphost
    var.jumphost1_subnet_cidr_block,
    var.jumphost2_subnet_cidr_block,
    # CI VPC
    var.ci_sg_ssh_cidr_blocks,
  ])
}

# need to allow filebeat to get to logstash
resource "aws_network_acl_rule" "elk-ingress-tcp-logstash" {
  network_acl_id = aws_network_acl.elk.id
  egress         = false
  from_port      = 5044
  to_port        = 5044
  protocol       = "tcp"
  rule_number    = 40
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr_block
}

# need so that jumphost can get to elk
resource "aws_network_acl_rule" "elk-ingress-tcp-elk-web1" {
  network_acl_id = aws_network_acl.elk.id
  egress         = false
  from_port      = 8443
  to_port        = 8443
  protocol       = "tcp"
  rule_number    = 46
  rule_action    = "allow"
  cidr_block     = var.jumphost1_subnet_cidr_block
}

resource "aws_network_acl_rule" "elk-ingress-tcp-elk-web2" {
  network_acl_id = aws_network_acl.elk.id
  egress         = false
  from_port      = 8443
  to_port        = 8443
  protocol       = "tcp"
  rule_number    = 47
  rule_action    = "allow"
  cidr_block     = var.jumphost2_subnet_cidr_block
}

