data "aws_ip_ranges" "route53" {
  regions  = ["global"]
  services = ["route53"]
}

# When adding a new subnet, be sure to add an association with a network ACL,
# or it will use the default NACL, which causes problems since the default
# network ACL is special and is handled weirdly by AWS and Terraform.
#
# If you don't explicitly give the subnet a NACL, a terraform plan will show an
# attempt to remove the default plan, which can't actually be done, so it will
# continually show that same plan.
#
# See https://www.terraform.io/docs/providers/aws/r/default_network_acl.html

resource "aws_elasticache_subnet_group" "idp" {
  name        = "${var.name}-idp-cache-${var.env_name}"
  description = "Redis Subnet Group"
  subnet_ids  = [aws_subnet.db1.id, aws_subnet.db2.id]
}

resource "aws_internet_gateway" "default" {
  tags = {
    Name = "${var.name}-gateway-${var.env_name}"
  }
  vpc_id = aws_vpc.default.id
}

resource "aws_route" "default" {
  route_table_id         = aws_vpc.default.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

# Base security group added to all instances, grants default permissions like
# ingress SSH and ICMP.
resource "aws_security_group" "base" {
  name        = "${var.env_name}-base"
  description = "Base security group for rules common to all instances"
  vpc_id      = aws_vpc.default.id

  tags = {
    Name = "${var.env_name}-base"
  }

  # allow SSH in from jumphost
  ingress {
    description     = "allow SSH in from jumphost"
    protocol        = "tcp"
    from_port       = 22
    to_port         = 22
    security_groups = [aws_security_group.jumphost.id]
  }

  # allow TCP egress to outbound proxy
  egress {
    description     = "allow egress to outbound proxy"
    protocol        = "tcp"
    from_port       = var.proxy_port
    to_port         = var.proxy_port
    security_groups = [aws_security_group.obproxy.id]
  }

  # allow ICMP to/from the whole VPC
  ingress {
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = [aws_vpc.default.cidr_block]
  }
  egress {
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = [aws_vpc.default.cidr_block]
  }

  # allow access to the VPC private S3 endpoint
  egress {
    description     = "allow egress to VPC S3 endpoint"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.private-s3.prefix_list_id]
  }
}

resource "aws_security_group" "app" {
  description = "Security group for sample app servers"

  # TODO: limit this to what is actually needed
  # allow outbound to the VPC so that we can get to db/redis/logstash/etc.
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # need to get packages and stuff (conditionally)
  # outbound_subnets can be set to "0.0.0.0/0" to allow access to the internet
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.outbound_subnets
  }

  # need to get packages and stuff (conditionally)
  # outbound_subnets can be set to "0.0.0.0/0" to allow access to the internet
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.outbound_subnets
  }

  # github
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["192.30.252.0/22"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.app-alb.id]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.app-alb.id]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.jumphost.id]
  }

  # allow CI VPC for integration tests
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ci_sg_ssh_cidr_blocks
  }

  name = "${var.env_name}-app"

  tags = {
    Name = "${var.name}-app_security_group-${var.env_name}"
    role = "app"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group" "cache" {
  description = "Allow inbound and outbound redis traffic with app subnet in vpc"

  egress {
    from_port = 6379
    to_port   = 6379
    protocol  = "tcp"
    security_groups = [
      aws_security_group.app.id,
      aws_security_group.idp.id,
    ]
  }

  ingress {
    from_port = 6379
    to_port   = 6379
    protocol  = "tcp"
    security_groups = [
      aws_security_group.app.id,
      aws_security_group.idp.id,
    ]
  }

  # allow CI VPC for integration tests
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ci_sg_ssh_cidr_blocks
  }

  name = "${var.name}-cache-${var.env_name}"

  tags = {
    Name = "${var.name}-cache_security_group-${var.env_name}"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group" "db" {
  description = "Allow inbound and outbound postgresql traffic with app subnet in vpc"

  egress = []

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    security_groups = [
      aws_security_group.app.id,
      aws_security_group.idp.id,
      aws_security_group.migration.id,
      aws_security_group.pivcac.id,
    ]
  }

  # allow CI VPC for integration tests
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ci_sg_ssh_cidr_blocks
  }

  name = "${var.name}-db-${var.env_name}"

  tags = {
    Name = "${var.name}-db_security_group-${var.env_name}"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group" "elk" {
  depends_on  = [aws_internet_gateway.default]
  description = "Allow inbound traffic to ELK from whitelisted IPs for SSH and app security group"

  # TODO: limit this to what is actually needed
  # allow outbound to the VPC so that we can get to db/redis/logstash/etc.
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # github
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["192.30.252.0/22"]
  }

  # need to get packages and stuff (conditionally)
  # outbound_subnets can be set to "0.0.0.0/0" to allow access to the internet
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.outbound_subnets
  }

  # need to get packages and stuff (conditionally)
  # outbound_subnets can be set to "0.0.0.0/0" to allow access to the internet
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.outbound_subnets
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.jumphost.id]
  }

  # need 8834 to comm with Nessus Server
  egress {
    from_port   = 8834
    to_port     = 8834
    protocol    = "tcp"
    cidr_blocks = [var.nessusserver_ip]
  }

  ingress {
    from_port = 5044
    to_port   = 5044
    protocol  = "tcp"
    self      = true
    cidr_blocks = [
      var.idp1_subnet_cidr_block,
      var.idp2_subnet_cidr_block,
      var.idp3_subnet_cidr_block,
      var.jumphost1_subnet_cidr_block,
      var.jumphost2_subnet_cidr_block,
      var.public1_subnet_cidr_block,
      var.public2_subnet_cidr_block,
      var.public3_subnet_cidr_block,
      var.private1_subnet_cidr_block,
      var.private2_subnet_cidr_block,
      var.private3_subnet_cidr_block,
    ]
  }

  ingress {
    from_port       = 8443
    to_port         = 8443
    protocol        = "tcp"
    security_groups = [aws_security_group.jumphost.id]
  }

  ingress {
    from_port = 9200
    to_port   = 9300
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port = 9200
    to_port   = 9300
    protocol  = "tcp"
    cidr_blocks = [
      var.elasticsearch_cidr_block,
      var.elk_cidr_block,
    ]
    description = "Needed for NLB since it does not support referring to sg ids"
  }

  # allow CI VPC for integration tests
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ci_sg_ssh_cidr_blocks
  }

  # need 8834 to comm with Nessus Server
  ingress {
    from_port   = 8834
    to_port     = 8834
    protocol    = "tcp"
    cidr_blocks = [var.nessusserver_ip]
  }

  name = "${var.name}-elk-${var.env_name}"

  tags = {
    Name              = "${var.name}-elk_security_group-${var.env_name}"
    role              = "elk"
    to_deprecate_role = "elasticsearch"
  }

  vpc_id = aws_vpc.default.id
}

# Create a security group with nothing in it that we can use to work around
# Terraform warts and break bootstrapping loops. For example, since Terraform
# can't handle a security group rule not having a group ID, we can put in this
# null group ID as a placeholder to break bootstrapping loops.
resource "aws_security_group" "null" {
  name        = "${var.env_name}-null"
  description = "Null security group for terraform hacks, do NOT put instances in it"
  vpc_id      = aws_vpc.default.id
  tags = {
    Name = "${var.env_name}-null"
  }

  ingress = []
  egress  = []
}

resource "aws_security_group" "jumphost" {
  description = "Allow inbound jumphost traffic: whitelisted IPs for SSH"

  # TODO: limit this to what is actually needed
  # allow outbound to the VPC so that we can get to db/redis/logstash/etc.
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # allow analytics redshift cluster to get into jumphost.
  # 127.0.0.1/32 is used as a meaningless default CIDR block in case
  # var.env_name is not a valid key to the redshift_cidr_block map.
  # TODO: remove this once peering connection is fully set up
  egress {
    from_port = 5439
    to_port   = 5439
    protocol  = "tcp"
    # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
    # force an interpolation expression to be interpreted as a list by wrapping it
    # in an extra set of list brackets. That form was supported for compatibility in
    # v0.11, but is no longer supported in Terraform v0.12.
    #
    # If the expression in the following list itself returns a list, remove the
    # brackets to avoid interpretation as a list of lists. If the expression
    # returns a single list item then leave it as-is and remove this TODO comment.
    cidr_blocks = [lookup(var.redshift_cidr_block, var.env_name, "127.0.0.1/32")]
  }

  # Allow egress to redshift in analytics VPC through peering connection
  egress {
    from_port = 5439
    to_port   = 5439
    protocol  = "tcp"

    # We'd like to refer to the analytics redshift security group ID, but it
    # might not exist yet. Terraform is not able to handle conditionals in a
    # good way (we have to set some security group ID here), so use the null
    # security group ID if the analytics group is empty string.
    security_groups = [var.analytics_redshift_security_group_id != "" ? var.analytics_redshift_security_group_id : aws_security_group.null.id]
  }

  # need 80/443 to get packages/gems/etc
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # need 80/443 to get packages/gems/etc
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # need 8834 to comm with Nessus Server
  egress {
    from_port   = 8834
    to_port     = 8834
    protocol    = "tcp"
    cidr_blocks = [var.nessusserver_ip]
  }

  # github
  egress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    # github
    cidr_blocks = ["192.30.252.0/22"]
  }

  # TODO split out ELB security group from jumphost SG
  egress {
    from_port = 22 # ELB

    to_port  = 22
    protocol = "tcp"
    self     = true
  }
  egress {
    from_port = 26 # ELB healthcheck

    to_port  = 26
    protocol = "tcp"
    self     = true
  }

  #s3 gateway
  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.private-s3.prefix_list_id]
  }

  ingress {
    from_port = 22 # ELB

    to_port  = 22
    protocol = "tcp"
    self     = true
  }
  ingress {
    from_port = 26 # ELB healthcheck

    to_port  = 26
    protocol = "tcp"
    self     = true
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    # Remote Access (FIXME rename variable to 'external_ssh_cidr_blocks'?)
    cidr_blocks = var.app_sg_ssh_cidr_blocks
  }

  # need 8834 to comm with Nessus Server
  ingress {
    from_port   = 8834
    to_port     = 8834
    protocol    = "tcp"
    cidr_blocks = [var.nessusserver_ip]
  }

  name = "${var.name}-jumphost-${var.env_name}"

  tags = {
    Name = "${var.name}-jumphost_security_group-${var.env_name}"
    role = "jumphost"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group" "idp" {
  description = "Allow inbound web traffic and whitelisted IP(s) for SSH"

  # TODO: limit this to what is actually needed
  # allow outbound to the VPC so that we can get to db/redis/logstash/etc.
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # need to get packages and stuff (conditionally)
  # outbound_subnets can be set to "0.0.0.0/0" to allow access to the internet
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.outbound_subnets
  }

  # need to get packages and stuff (conditionally)
  # outbound_subnets can be set to "0.0.0.0/0" to allow access to the internet
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.outbound_subnets
  }

  # Allow egress to CloudHSM
  egress {
    description = "Allow egress to CloudHSM"
    from_port   = 2223
    to_port     = 2225
    protocol    = "tcp"

    # can't use security_groups on account of terraform cycle
    # https://github.com/terraform-providers/terraform-provider-aws/issues/3234
    #security_groups = ["${aws_security_group.cloudhsm.id}"]
    cidr_blocks = [
      aws_subnet.idp1.cidr_block,
      aws_subnet.idp2.cidr_block,
    ]
  }

  # gpo
  egress {
    description = "Permit SFTP access to GPO for file transfer of USPS confirmations and undeliverable address codes"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
      "162.140.252.160/32",
      "162.140.64.26/32",
    ]
  }

  # github
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["192.30.252.0/22"]
  }

  # need 8834 to comm with Nessus Server
  egress {
    from_port   = 8834
    to_port     = 8834
    protocol    = "tcp"
    cidr_blocks = [var.nessusserver_ip]
  }

  #s3 gateway
  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.private-s3.prefix_list_id]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.jumphost.id]
  }

  # allow CI VPC for integration tests
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ci_sg_ssh_cidr_blocks
  }

  # need 8834 to comm with Nessus Server
  ingress {
    from_port   = 8834
    to_port     = 8834
    protocol    = "tcp"
    cidr_blocks = [var.nessusserver_ip]
  }

  name = "${var.name}-idp-${var.env_name}"

  tags = {
    Name = "${var.name}-idp_security_group-${var.env_name}"
    role = "idp"
  }

  vpc_id = aws_vpc.default.id
}

# You can't change the security group used by a CloudHSM cluster, so you have
# to import the security group under this ID in order to have terraform manage
# it. (Yes, this is all a huge pain.)
#
# Wrapper script:
#   bin/oneoffs/cloudhsm-import-security-group.rb ENV
#
# Direct import (what ^ does under the hood):
#   terraform import aws_security_group.cloudhsm sg-12345678
#
resource "aws_security_group" "cloudhsm" {
  name        = "${var.env_name}-cloudhsm-tf-placeholder"
  description = "CloudHSM security group (terraform placeholder, delete me)"
  vpc_id      = aws_vpc.default.id

  # We ignore changes to the name and description since they can't be edited.
  lifecycle {
    ignore_changes = [
      name,
      description,
    ]
  }

  tags = {
    Name = "${var.env_name}-cloudhsm"
  }

  # Allow ingress to CloudHSM ports from IDP and from other CloudHSM instances
  ingress {
    from_port       = 2223
    to_port         = 2225
    protocol        = "tcp"
    security_groups = [aws_security_group.idp.id]
    self            = true
  }

  # Allow egress to CloudHSM ports to other cluster instances
  egress {
    from_port = 2223
    to_port   = 2225
    protocol  = "tcp"
    self      = true
  }

  # Allow ICMP from IDP
  ingress {
    from_port       = -1
    to_port         = -1
    protocol        = "icmp"
    security_groups = [aws_security_group.idp.id]
  }
}

resource "aws_security_group" "migration" {
  name = "${var.env_name}-migration"

  tags = {
    Name = "${var.env_name}-migration"
    role = "migration"
  }

  vpc_id      = aws_vpc.default.id
  description = "Security group for migration server role"

  # TODO: limit this to what is actually needed
  # allow outbound to the VPC so that we can get to db/redis/logstash/etc.
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # github
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["192.30.252.0/22"]
  }

  # need 8834 to comm with Nessus Server
  egress {
    from_port   = 8834
    to_port     = 8834
    protocol    = "tcp"
    cidr_blocks = [var.nessusserver_ip]
  }

  #s3 gateway
  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.private-s3.prefix_list_id]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.jumphost.id]
  }

  # allow CI VPC for integration tests
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ci_sg_ssh_cidr_blocks
  }

  # need 8834 to comm with Nessus Server
  ingress {
    from_port   = 8834
    to_port     = 8834
    protocol    = "tcp"
    cidr_blocks = [var.nessusserver_ip]
  }
}

resource "aws_security_group" "pivcac" {
  description = "Allow inbound web traffic and whitelisted IP(s) for SSH"

  # TODO: limit this to what is actually needed
  # allow outbound to the VPC so that we can get to db/redis/logstash/etc.
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # need to get packages and stuff (conditionally)
  # outbound_subnets can be set to "0.0.0.0/0" to allow access to the internet
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.outbound_subnets
  }

  # need to get packages and stuff (conditionally)
  # outbound_subnets can be set to "0.0.0.0/0" to allow access to the internet
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.outbound_subnets
  }

  # github
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["192.30.252.0/22"]
  }

  #s3 gateway
  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.private-s3.prefix_list_id]
  }

  # We should never need port 80 for PIVCAC ingress, because users should only
  # arrive via links/redirects from the IDP.
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.jumphost.id]
  }

  # allow CI VPC for integration tests
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ci_sg_ssh_cidr_blocks
  }

  # need 8834 to comm with Nessus Server
  egress {
    from_port   = 8834
    to_port     = 8834
    protocol    = "tcp"
    cidr_blocks = [var.nessusserver_ip]
  }

  name = "${var.name}-pivcac-${var.env_name}"

  tags = {
    Name = "${var.name}-pivcac_security_group-${var.env_name}"
    role = "pivcac"
  }

  vpc_id = aws_vpc.default.id
}

# TODO rename to idp-alb
resource "aws_security_group" "web" {
  # TODO: description = "idp-alb security group allowing web traffic"
  description = "Security group for web that allows web traffic from internet"
  vpc_id      = aws_vpc.default.id

  # Allow outbound to the IDP subnets on 80/443.
  #
  # We use cidr_blocks rather than security_groups here so that we avoid a
  # bootstrapping cycle and will still remove unmanaged rules.
  # https://github.com/terraform-providers/terraform-provider-aws/issues/3095
  egress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = [
      var.idp1_subnet_cidr_block,
      var.idp2_subnet_cidr_block,
      var.idp3_subnet_cidr_block,
    ]
  }
  egress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [
      var.idp1_subnet_cidr_block,
      var.idp2_subnet_cidr_block,
      var.idp3_subnet_cidr_block,
    ]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  name = "${var.name}-web-${var.env_name}"

  tags = {
    Name = "${var.env_name}-idp-alb"
  }
}

resource "aws_security_group" "app-alb" {
  description = "App ALB group allowing Internet traffic"
  vpc_id      = aws_vpc.default.id

  # Allow outbound to the VPC so that we can get to the app hosts.
  # We use cidr_blocks rather than security_groups here so that we avoid a
  # bootstrapping cycle and will still remove unmanaged rules.
  # https://github.com/terraform-providers/terraform-provider-aws/issues/3095
  egress {
    description = "Permit HTTP to public subnets for app"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [
      aws_subnet.publicsubnet1.cidr_block,
      aws_subnet.publicsubnet2.cidr_block,
      aws_subnet.publicsubnet3.cidr_block,
    ]
  }
  egress {
    description = "Permit HTTPS to public subnets for app"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [
      aws_subnet.publicsubnet1.cidr_block,
      aws_subnet.publicsubnet2.cidr_block,
      aws_subnet.publicsubnet3.cidr_block,
    ]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  name = "${var.env_name}-app-alb"

  tags = {
    Name = "${var.env_name}-app-alb"
  }
}

resource "aws_subnet" "db1" {
  availability_zone       = "${var.region}a"
  cidr_block              = var.db1_subnet_cidr_block
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name}-db1_subnet-${var.env_name}"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_subnet" "db2" {
  availability_zone       = "${var.region}b"
  cidr_block              = var.db2_subnet_cidr_block
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name}-db2_subnet-${var.env_name}"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_subnet" "jumphost1" {
  availability_zone       = "${var.region}a"
  cidr_block              = var.jumphost1_subnet_cidr_block
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-jumphost1_subnet-${var.env_name}"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_subnet" "jumphost2" {
  availability_zone       = "${var.region}b"
  cidr_block              = var.jumphost2_subnet_cidr_block
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-jumphost2_subnet-${var.env_name}"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_subnet" "idp1" {
  availability_zone       = "${var.region}a"
  cidr_block              = var.idp1_subnet_cidr_block
  depends_on              = [aws_internet_gateway.default]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-idp1_subnet-${var.env_name}"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_subnet" "idp2" {
  availability_zone       = "${var.region}b"
  cidr_block              = var.idp2_subnet_cidr_block
  depends_on              = [aws_internet_gateway.default]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-idp2_subnet-${var.env_name}"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_subnet" "alb1" {
  availability_zone       = "${var.region}a"
  cidr_block              = var.alb1_subnet_cidr_block
  depends_on              = [aws_internet_gateway.default]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-alb1_subnet-${var.env_name}"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_subnet" "alb2" {
  availability_zone       = "${var.region}b"
  cidr_block              = var.alb2_subnet_cidr_block
  depends_on              = [aws_internet_gateway.default]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-alb2_subnet-${var.env_name}"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_vpc_endpoint" "private-s3" {
  vpc_id          = aws_vpc.default.id
  service_name    = "com.amazonaws.${var.region}.s3"
  route_table_ids = [aws_vpc.default.main_route_table_id]
}

resource "aws_vpc" "default" {
  cidr_block = var.vpc_cidr_block

  # main_route_table_id = "${aws_route_table.default.id}"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name}-vpc-${var.env_name}"
  }
}

# create public and private subnets
resource "aws_subnet" "publicsubnet1" {
  availability_zone       = "${var.region}a"
  cidr_block              = var.public1_subnet_cidr_block
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-public1_subnet-${var.env_name}"
    type = "public"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_subnet" "publicsubnet2" {
  availability_zone       = "${var.region}b"
  cidr_block              = var.public2_subnet_cidr_block
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-public2_subnet-${var.env_name}"
    type = "public"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_subnet" "publicsubnet3" {
  availability_zone       = "${var.region}c"
  cidr_block              = var.public3_subnet_cidr_block
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-public3_subnet-${var.env_name}"
    type = "public"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_subnet" "privatesubnet1" {
  availability_zone = "${var.region}a"
  cidr_block        = var.private1_subnet_cidr_block

  tags = {
    Name = "${var.name}-private1_subnet-${var.env_name}"
    type = "private"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_subnet" "privatesubnet2" {
  availability_zone = "${var.region}b"
  cidr_block        = var.private2_subnet_cidr_block

  tags = {
    Name = "${var.name}-private2_subnet-${var.env_name}"
    type = "private"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_subnet" "privatesubnet3" {
  availability_zone = "${var.region}c"
  cidr_block        = var.private3_subnet_cidr_block

  tags = {
    Name = "${var.name}-private3_subnet-${var.env_name}"
    type = "private"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group" "obproxy" {
  description = "Allow inbound web traffic and whitelisted IP(s) for SSH"

  # TODO: limit this to what is actually needed
  # allow outbound to the VPC so that we can get to db/redis/logstash/etc.
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # need 80/443 to get packages/gems/etc
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # need 80/443 to get packages/gems/etc
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow github access to their static cidr block
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["192.30.252.0/22"]
  }

  #s3 gateway
  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.private-s3.prefix_list_id]
  }

  # need 8834 to comm with Nessus Server
  egress {
    from_port   = 8834
    to_port     = 8834
    protocol    = "tcp"
    cidr_blocks = [var.nessusserver_ip]
  }

  # Allow egress to AAMVA
  egress {
    from_port = 18449
    to_port   = 18449
    protocol  = "tcp"
    cidr_blocks = [
      "66.227.17.192/26",
      "66.16.0.0/16",
    ] # This IP range includes AAMVA's failover, but is not exclusively controlled by AAMVA
  }

  ingress {
    from_port   = 3128
    to_port     = 3128
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.jumphost.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ci_sg_ssh_cidr_blocks
  }

  name = "${var.name}-obproxy-${var.env_name}"

  tags = {
    Name = "${var.name}-obproxy-${var.env_name}"
    role = "outboundproxy"
  }

  vpc_id = aws_vpc.default.id
}

module "vpc_flow_cloudwatch_filters" {
  source = "github.com/18F/identity-terraform//vpc_flow_cloudwatch_filters?ref=379b9ca062233ddf26b69c021b7a8546532ec934"

  env_name      = var.env_name
  alarm_actions = [var.slack_events_sns_hook_arn]
}

