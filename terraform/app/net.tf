data "aws_ip_ranges" "route53" {
  regions  = ["global"]
  services = ["route53"]
}

locals {
  net_ssm_parameter_prefix = "/${var.env_name}/network/"
  ip_regex                 = "^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}\\/(?:[0-2][0-9]|[3][0-2])"
  github_ipv4 = compact([
    for ip in data.github_ip_ranges.ips.git : try(regex(local.ip_regex, ip), "")
  ])
  network_layout            = module.network_layout.network_layout
  nessus_public_access_mode = var.root_domain == "identitysandbox.gov" && var.allow_nessus_external_scanning ? true : false
}

module "network_layout" {
  source = "../modules/network_layout"
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
  subnet_ids  = [for subnet in aws_subnet.data-services : subnet.id]
}

resource "aws_db_subnet_group" "aurora" {
  name        = "${var.name}-rds-${var.env_name}"
  description = "RDS Aurora Subnet Group for ${var.env_name} environment"
  subnet_ids  = [for subnet in aws_subnet.data-services : subnet.id]
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
    cidr_blocks = [aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }
  egress {
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = [aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  # allow access to the VPC private S3 endpoint
  egress {
    description     = "allow egress to VPC S3 endpoint"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.private-s3.prefix_list_id]
  }

  # GARBAGE TEMP - Allow direct access to api.snapcraft.io until Ubuntu Advantage stops
  #                hanging on repeated calls to pull the livestream agent from snap
  egress {
    description = "allow egress to api.snapcraft.io"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["91.189.92.0/24"]
  }
}

resource "aws_security_group" "app" {
  count       = var.apps_enabled
  description = "Security group for sample app servers"

  # TODO: limit this to what is actually needed
  # allow outbound to the VPC so that we can get to db/redis/logstash/etc.
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
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
    cidr_blocks = local.github_ipv4
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.app-alb[count.index].id]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.app-alb[count.index].id]
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
      aws_security_group.idp.id,
      aws_security_group.worker.id,
    ]
  }

  ingress {
    from_port = 6379
    to_port   = 6379
    protocol  = "tcp"
    security_groups = [
      aws_security_group.idp.id,
      aws_security_group.worker.id,
    ]
  }

  dynamic "ingress" {
    for_each = local.nessus_public_access_mode ? [1] : []
    content {
      from_port   = 6379
      to_port     = 6379
      protocol    = "tcp"
      cidr_blocks = [for subnet in aws_subnet.public-ingress : subnet.cidr_block]
    }
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
    from_port = var.rds_db_port
    to_port   = var.rds_db_port
    protocol  = "tcp"
    security_groups = compact([
      aws_security_group.idp.id,
      aws_security_group.migration.id,
      aws_security_group.pivcac.id,
      aws_security_group.worker.id,
      var.apps_enabled == 1 ? aws_security_group.app[0].id : ""
    ])
  }

  dynamic "ingress" {
    for_each = local.nessus_public_access_mode ? [1] : []
    content {
      description = "Inbound Nessus Scanning"
      from_port   = var.rds_db_port
      to_port     = var.rds_db_port
      protocol    = "tcp"
      cidr_blocks = [var.nessusserver_ip]
    }
  }

  name = "${var.name}-db-${var.env_name}"

  tags = {
    Name = "${var.name}-db_security_group-${var.env_name}"
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

resource "aws_security_group" "idp" {
  description = "Allow inbound web traffic and whitelisted IP(s) for SSH"

  # TODO: limit this to what is actually needed
  # allow outbound to the VPC so that we can get to db/redis/logstash/etc.
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
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
    cidr_blocks = [for subnet in aws_subnet.app : subnet.cidr_block]
  }

  # gpo
  egress {
    description = "Permit SFTP access to GPO for file transfer of USPS confirmations and undeliverable address codes"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
      "162.140.252.175/32", # nsftp.gpo.gov - Primary
      "162.140.64.175/32",  # nsftp.gpo.gov - Backup
      "162.140.252.160/32", # Old GPO SFTP - Remove when cutover to nsftp.gpo.gov
      "162.140.64.26/32",   # Old GPO SFTP - Remove when cutover to nsftp.gpo.gov
    ]
  }

  # github
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.github_ipv4
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

  # need 8834 to comm with Nessus Server
  ingress {
    from_port   = 8834
    to_port     = 8834
    protocol    = "tcp"
    cidr_blocks = [var.nessusserver_ip]
  }

  # inbound from lambda functions
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for subnet in aws_subnet.app : subnet.cidr_block]
  }

  name = "${var.name}-idp-${var.env_name}"

  tags = {
    Name = "${var.name}-idp_security_group-${var.env_name}"
    role = "idp"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_ssm_parameter" "net_idp_securitygroup" {
  name  = "${local.net_ssm_parameter_prefix}securitygroup/idp/id"
  type  = "String"
  value = aws_security_group.idp.id
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
    cidr_blocks = [aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  # github
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.github_ipv4
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
    cidr_blocks = [aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
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
    cidr_blocks = local.github_ipv4
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
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [for subnet in aws_subnet.app : subnet.cidr_block]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for subnet in aws_subnet.app : subnet.cidr_block]
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
  count       = var.apps_enabled
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
    cidr_blocks = [for subnet in aws_subnet.app : subnet.cidr_block]
  }
  egress {
    description = "Permit HTTPS to public subnets for app"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for subnet in aws_subnet.app : subnet.cidr_block]
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

resource "aws_security_group" "worker-alb" {
  description = "Worker ALB group allowing monitoring from authorized ip addresses"
  vpc_id      = aws_vpc.default.id

  egress {
    description = "Permit HTTP to public subnets for app"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [for subnet in aws_subnet.app : subnet.cidr_block]
  }
  egress {
    description = "Permit HTTPS to public subnets for app"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for subnet in aws_subnet.app : subnet.cidr_block]
  }

  ingress {
    description = "Permit HTTP to workers for health checks"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = concat([aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block], var.worker_sg_ingress_permitted_ips)
  }

  ingress {
    description = "Permit HTTPS to workers for health checks"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = concat([aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block], var.worker_sg_ingress_permitted_ips)
  }

  name = "${var.env_name}-worker-alb"

  tags = {
    Name = "${var.env_name}-worker-alb"
  }
}

resource "aws_vpc_endpoint" "private-s3" {
  vpc_id          = aws_vpc.default.id
  service_name    = "com.amazonaws.${var.region}.s3"
  route_table_ids = [aws_vpc.default.main_route_table_id]
}

resource "aws_vpc" "default" {
  cidr_block = var.vpc_cidr_block

  # main_route_table_id = "${aws_route_table.default.id}"
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true

  tags = {
    Name = "${var.name}-vpc-${var.env_name}"
  }
}


resource "aws_ssm_parameter" "net_vpcid" {
  name  = "${local.net_ssm_parameter_prefix}vpc/id"
  type  = "String"
  value = aws_vpc.default.id
}

# use route53 for dns query logging
resource "aws_route53_resolver_query_log_config" "vpc" {
  name            = "${var.name}-vpc-${var.env_name}"
  destination_arn = aws_cloudwatch_log_group.dns_query_log.arn

}

resource "aws_route53_resolver_query_log_config_association" "vpc" {
  resolver_query_log_config_id = aws_route53_resolver_query_log_config.vpc.id
  resource_id                  = aws_vpc.default.id
}

resource "aws_route53_resolver_dnssec_config" "vpc" {
  resource_id = aws_vpc.default.id
}

resource "aws_security_group" "obproxy" {
  description = "Allow inbound web traffic and whitelisted IP(s) for SSH"

  # TODO: limit this to what is actually needed
  # allow outbound to the VPC so that we can get to db/redis/logstash/etc.
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
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
    cidr_blocks = local.github_ipv4
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
      "66.192.89.112/32",
      "66.192.89.94/32",
      "207.67.47.0/24",
    ] # This IP range includes AAMVA's failover, but is not exclusively controlled by AAMVA
  }

  # Allow egress to GSA Public Bigfix Relay Server
  egress {
    from_port = 52311
    to_port   = 52311
    protocol  = "tcp"
    cidr_blocks = [
      "3.209.219.136/32"
    ]
  }

  # Allow egress to Experian
  egress {
    from_port = 8443
    to_port   = 8443
    protocol  = "tcp"
    cidr_blocks = [
      "167.107.58.9/32",
    ]
  }

  ingress {
    from_port   = 3128
    to_port     = 3128
    protocol    = "tcp"
    cidr_blocks = [aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  name = "${var.name}-obproxy-${var.env_name}"

  tags = {
    Name = "${var.name}-obproxy-${var.env_name}"
    role = "outboundproxy"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group" "worker" {
  description = "Worker role"

  # allow outbound to the VPC
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  # need to get packages and stuff (conditionally)
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.outbound_subnets
  }

  # need to get packages and stuff (conditionally)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.outbound_subnets
  }

  # gpo
  egress {
    description = "Permit SFTP access to GPO for file transfer of USPS confirmations and undeliverable address codes"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
      "162.140.252.175/32", # nsftp.gpo.gov - Primary
      "162.140.64.175/32",  # nsftp.gpo.gov - Backup
      "162.140.252.160/32", # Old GPO SFTP - Remove when cutover to nsftp.gpo.gov
      "162.140.64.26/32",   # Old GPO SFTP - Remove when cutover to nsftp.gpo.gov
    ]
  }

  # github
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.github_ipv4
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

  # need 8834 to comm with Nessus Server
  ingress {
    from_port   = 8834
    to_port     = 8834
    protocol    = "tcp"
    cidr_blocks = [var.nessusserver_ip]
  }


  # Allow Health Checks from ALBs
  ingress {
    description = "Permit HTTP to workers for health checks"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [
      aws_security_group.worker-alb.id,
    ]
  }

  ingress {
    description = "Permit HTTPS to workers for health checks"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [
      aws_security_group.worker-alb.id,
    ]
  }

  name = "${var.name}-worker-${var.env_name}"

  tags = {
    Name = "${var.name}-worker_security_group-${var.env_name}"
    role = "idp"
  }

  vpc_id = aws_vpc.default.id
}

module "vpc_flow_cloudwatch_filters" {
  source = "github.com/18F/identity-terraform//vpc_flow_cloudwatch_filters?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/vpc_flow_cloudwatch_filters"
  depends_on = [aws_cloudwatch_log_group.flow_log_group]

  env_name      = var.env_name
  alarm_actions = [var.slack_events_sns_hook_arn]
}

resource "aws_ssm_parameter" "net_outboundproxy" {
  name  = "${local.net_ssm_parameter_prefix}outboundproxy/url"
  type  = "String"
  value = "http://${var.proxy_server}:${var.proxy_port}"
}

resource "aws_ssm_parameter" "net_noproxy" {
  name  = "${local.net_ssm_parameter_prefix}outboundproxy/no_proxy"
  type  = "String"
  value = var.no_proxy_hosts
}
resource "aws_security_group" "quarantine" {
  name        = "${var.env_name}-quarantine"
  description = "Quarantine security group to access quarantined ec2 instances"
  vpc_id      = aws_vpc.default.id

  ingress {
    description = "allow 443 from VPC"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = [aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }
  egress {
    description     = "allow egress to VPC S3 endpoint"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.private-s3.prefix_list_id]
  }

  egress {
    description     = "allow egress to endpoints"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2messages_endpoint.id, aws_security_group.ssmmessages_endpoint.id, aws_security_group.ssm_endpoint.id, aws_security_group.logs_endpoint.id]
  }

  tags = {
    Name        = "${var.env_name}-quarantine"
    description = "Quarantine Security Group"
  }
}

resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
  vpc_id     = aws_vpc.default.id
  cidr_block = local.network_layout[var.region][var.env_type]._network
}

resource "aws_subnet" "app" {
  for_each                = local.network_layout[var.region][var.env_type]._zones
  availability_zone       = "${var.region}${each.key}"
  cidr_block              = each.value.apps.ipv4-cidr
  depends_on              = [aws_internet_gateway.default]
  map_public_ip_on_launch = true

  ## Example Enablement of IPv6 for app subnets.
  # ipv6_cidr_block = cidrsubnet(aws_vpc.default.ipv6_cidr_block, 8, each.value.apps.ipv6-netnum)

  tags = {
    Name = "${var.name}-app_subnet_${each.key}-${var.env_name}"
  }

  vpc_id = aws_vpc_ipv4_cidr_block_association.secondary_cidr.vpc_id
}

resource "aws_subnet" "data-services" {
  for_each                = local.network_layout[var.region][var.env_type]._zones
  availability_zone       = "${var.region}${each.key}"
  cidr_block              = each.value.data-services.ipv4-cidr
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name}-data_services_subnet_${each.key}-${var.env_name}"
  }

  vpc_id = aws_vpc_ipv4_cidr_block_association.secondary_cidr.vpc_id
}

resource "aws_subnet" "public-ingress" {
  for_each                = local.network_layout[var.region][var.env_type]._zones
  availability_zone       = "${var.region}${each.key}"
  cidr_block              = each.value.public-ingress.ipv4-cidr
  map_public_ip_on_launch = true

  ipv6_cidr_block = cidrsubnet(aws_vpc.default.ipv6_cidr_block, 8, each.value.public-ingress.ipv6-netnum)

  tags = {
    Name = "${var.name}-public_ingress_subnet_${each.key}-${var.env_name}"
  }

  vpc_id = aws_vpc_ipv4_cidr_block_association.secondary_cidr.vpc_id
}
