locals {
  net_ssm_parameter_prefix = "/${var.env_name}/network/"
  ip_regex                 = "^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}\\/(?:[0-2][0-9]|[3][0-2])"
  github_ipv4 = compact([
    for ip in data.github_ip_ranges.ips.git : try(regex(local.ip_regex, ip), "")
  ])
  network_layout = module.network_layout.network_layout
  nessus_public_access_mode = (
    var.root_domain == "identitysandbox.gov" && var.allow_nessus_external_scanning ?
    true : false
  )
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
  subnet_ids  = [for subnet in module.network_uw2.db_subnet : subnet.id]
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

  vpc_id = module.network_uw2.vpc_id
}

resource "aws_security_group" "app" {
  count       = var.apps_enabled
  description = "Security group for sample app servers"

  vpc_id = module.network_uw2.vpc_id

  # TODO: limit this to what is actually needed
  # allow outbound to the VPC so that we can get to db/redis/logstash/etc.
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [module.network_uw2.secondary_cidr]
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
}

resource "aws_security_group" "app-alb" {
  count       = var.apps_enabled
  description = "App ALB group allowing Internet traffic"
  vpc_id      = module.network_uw2.vpc_id

  # Allow outbound to the VPC so that we can get to the app hosts.
  # We use cidr_blocks rather than security_groups here so that we avoid a
  # bootstrapping cycle and will still remove unmanaged rules.
  # https://github.com/terraform-providers/terraform-provider-aws/issues/3095
  egress {
    description = "Permit HTTP to public subnets for app"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [for subnet in module.network_uw2.app_subnet : subnet.cidr_block]
  }
  egress {
    description = "Permit HTTPS to public subnets for app"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for subnet in module.network_uw2.app_subnet : subnet.cidr_block]
  }

  # remove when HTTP access no longer needed
  ingress {
    description     = "Permit HTTP from Cloudfront Edge Resources"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    prefix_list_ids = [module.network_uw2.cloudfront_prefix_list_id]
  }

  ingress {
    description     = "Permit HTTPS from Cloudfront Edge Resources"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [module.network_uw2.cloudfront_prefix_list_id]
  }

  name = "${var.env_name}-app-alb"

  tags = {
    Name = "${var.env_name}-app-alb"
  }
}

resource "aws_security_group" "idp" {
  description = "Allow inbound web traffic and whitelisted IP(s) for SSH"

  # TODO: limit this to what is actually needed
  # allow outbound to the VPC so that we can get to db/redis/logstash/etc.
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [module.network_uw2.secondary_cidr]
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
    cidr_blocks = [for subnet in module.network_uw2.app_subnet : subnet.cidr_block]
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
    prefix_list_ids = [module.network_uw2.s3_prefix_list_id]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.idp-alb.id]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.idp-alb.id]
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
    cidr_blocks = [for subnet in module.network_uw2.app_subnet : subnet.cidr_block]
  }

  name = "${var.name}-idp-${var.env_name}"

  tags = {
    Name = "${var.name}-idp_security_group-${var.env_name}"
    role = "idp"
  }

  vpc_id = module.network_uw2.vpc_id
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
  vpc_id      = module.network_uw2.vpc_id

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

resource "aws_security_group" "pivcac" {
  description = "Allow inbound web traffic and whitelisted IP(s) for SSH"

  # TODO: limit this to what is actually needed
  # allow outbound to the VPC so that we can get to db/redis/logstash/etc.
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [module.network_uw2.secondary_cidr]
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
    prefix_list_ids = [module.network_uw2.s3_prefix_list_id]
  }

  # We should never need port 80 for PIVCAC ingress, because users should only
  # arrive via links/redirects from the IDP.
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.pivcac-elb.id]
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

  vpc_id = module.network_uw2.vpc_id
}

resource "aws_security_group" "pivcac-elb" {
  description = "pivcac-elb security group allowing web traffic"
  vpc_id      = module.network_uw2.vpc_id

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [for subnet in module.network_uw2.app_subnet : subnet.cidr_block]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for subnet in module.network_uw2.app_subnet : subnet.cidr_block]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-vpc-no-public-ingress-sg
  }

  name = "${var.env_name}-pivcac-elb"

  tags = {
    Name = "${var.env_name}-pivcac-elb"
  }
}

resource "aws_security_group" "idp-alb" {
  description = "idp-alb security group allowing web traffic"
  vpc_id      = module.network_uw2.vpc_id

  # Allow outbound to the IDP subnets on 80/443.
  #
  # We use cidr_blocks rather than security_groups here so that we avoid a
  # bootstrapping cycle and will still remove unmanaged rules.
  # https://github.com/terraform-providers/terraform-provider-aws/issues/3095
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [for subnet in module.network_uw2.app_subnet : subnet.cidr_block]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for subnet in module.network_uw2.app_subnet : subnet.cidr_block]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    prefix_list_ids = [module.network_uw2.cloudfront_prefix_list_id]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [module.network_uw2.cloudfront_prefix_list_id]
  }

  name = "${var.env_name}-idp-alb"

  tags = {
    Name = "${var.env_name}-idp-alb"
  }
}

resource "aws_security_group" "worker-alb" {
  description = "Worker ALB group allowing monitoring from authorized ip addresses"
  vpc_id      = module.network_uw2.vpc_id

  egress {
    description = "Permit HTTP to public subnets for app"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [for subnet in module.network_uw2.app_subnet : subnet.cidr_block]
  }
  egress {
    description = "Permit HTTPS to public subnets for app"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for subnet in module.network_uw2.app_subnet : subnet.cidr_block]
  }

  ingress {
    description = "Permit HTTP to workers for health checks"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = concat(
      [module.network_uw2.secondary_cidr],
      var.worker_sg_ingress_permitted_ips
    )
  }

  ingress {
    description = "Permit HTTPS to workers for health checks"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = concat(
      [module.network_uw2.secondary_cidr],
      var.worker_sg_ingress_permitted_ips
    )
  }

  name = "${var.env_name}-worker-alb"

  tags = {
    Name = "${var.env_name}-worker-alb"
  }
}


resource "aws_ssm_parameter" "net_vpcid" {
  name  = "${local.net_ssm_parameter_prefix}vpc/id"
  type  = "String"
  value = module.network_uw2.vpc_id
}

# use route53 for dns query logging
resource "aws_route53_resolver_query_log_config" "vpc" {
  name            = "${var.name}-vpc-${var.env_name}"
  destination_arn = aws_cloudwatch_log_group.dns_query_log.arn

}

resource "aws_route53_resolver_query_log_config_association" "vpc" {
  resolver_query_log_config_id = aws_route53_resolver_query_log_config.vpc.id
  resource_id                  = module.network_uw2.vpc_id
}

resource "aws_route53_resolver_dnssec_config" "vpc" {
  resource_id = module.network_uw2.vpc_id
}

resource "aws_security_group" "worker" {
  description = "Worker role"

  # allow outbound to the VPC
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [module.network_uw2.secondary_cidr]
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
    prefix_list_ids = [module.network_uw2.s3_prefix_list_id]
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

  vpc_id = module.network_uw2.vpc_id
}

module "vpc_flow_cloudwatch_filters" {
  source = "github.com/18F/identity-terraform//vpc_flow_cloudwatch_filters?ref=06c8ddd069ed1eea84785033f87b7560eaf0ef6f"
  #source     = "../../../identity-terraform/vpc_flow_cloudwatch_filters"
  depends_on = [module.network_uw2]

  env_name      = var.env_name
  alarm_actions = [var.slack_alarms_sns_hook_arn]
  vpc_flow_rejections_internal_fields = {
    action  = "action=REJECT"
    srcAddr = "srcAddr=172.16.* || srcAddr=100.106.*"
  }
  vpc_flow_rejections_unexpected_fields = {
    action  = "action=REJECT"
    srcAddr = "srcAddr=172.16.* || srcAddr=100.106.*"
    dstAddr = "dstAddr!=192.88.99.255"
    srcPort = "srcPort!=26 && srcPort!=443 && srcPort!=3128 && srcPort!=5044"
  }
}

resource "aws_ssm_parameter" "net_outboundproxy" {
  name  = "${local.net_ssm_parameter_prefix}outboundproxy/url"
  type  = "String"
  value = "http://${var.proxy_server}:${var.proxy_port}"
}

resource "aws_ssm_parameter" "net_noproxy" {
  name  = "${local.net_ssm_parameter_prefix}outboundproxy/no_proxy"
  type  = "String"
  value = local.no_proxy_hosts
}
resource "aws_security_group" "quarantine" {
  name        = "${var.env_name}-quarantine"
  description = "Quarantine security group to access quarantined ec2 instances"
  vpc_id      = module.network_uw2.vpc_id

  ingress {
    description = "allow 443 from VPC"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = [module.network_uw2.secondary_cidr]
  }
  egress {
    description     = "allow egress to VPC S3 endpoint"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [module.network_uw2.s3_prefix_list_id]
  }

  egress {
    description = "allow egress to endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [
      module.network_uw2.endpoint_sg["ec2messages"],
      module.network_uw2.endpoint_sg["ssmmessages"],
      module.network_uw2.endpoint_sg["ssm"],
      module.network_uw2.endpoint_sg["logs"]
    ]
  }

  tags = {
    Name        = "${var.env_name}-quarantine"
    description = "Quarantine Security Group"
  }
}

resource "aws_subnet" "public-ingress" {
  for_each                = local.network_layout[var.region][var.env_type]._zones
  availability_zone       = "${var.region}${each.key}"
  cidr_block              = each.value.public-ingress.ipv4-cidr
  map_public_ip_on_launch = true

  ipv6_cidr_block = cidrsubnet(
    module.network_uw2.ipv6_cidr_block, 8, each.value.public-ingress.ipv6-netnum
  )

  tags = {
    Name = "${var.name}-public_ingress_subnet_${each.key}-${var.env_name}"
  }

  vpc_id = module.network_uw2.vpc_id
}

### Calling vpc module for us-east-1 ###

module "network_use1" {
  count = var.enable_us_east_1_vpc ? 1 : 0
  providers = {
    aws = aws.use1
  }

  source                    = "../modules/vpc_module"
  aws_services              = local.aws_endpoints
  az                        = local.network_layout["us-east-1"][var.env_type]._zones
  env_name                  = var.env_name
  env_type                  = var.env_type
  fisma_tag                 = var.fisma_tag
  flow_log_iam_role_arn     = module.application_iam_roles.flow_role_iam_role_arn
  github_ipv4_cidr_blocks   = local.github_ipv4
  nessusserver_ip           = var.nessusserver_ip
  nessus_public_access_mode = local.nessus_public_access_mode
  proxy_port                = var.proxy_port
  rds_db_port               = var.rds_db_port
  region                    = "us-east-1"
  secondary_cidr_block      = local.network_layout["us-east-1"][var.env_type]._network
  vpc_cidr_block            = var.us_east_1_vpc_cidr_block
  cloudwatch_retention_days = local.retention_days
}

### Calling vpc module for us-west-2 ###

module "network_uw2" {
  source                    = "../modules/vpc_module"
  aws_services              = local.aws_endpoints
  az                        = local.network_layout[var.region][var.env_type]._zones
  env_name                  = var.env_name
  env_type                  = var.env_type
  fisma_tag                 = var.fisma_tag
  flow_log_iam_role_arn     = module.application_iam_roles.flow_role_iam_role_arn
  github_ipv4_cidr_blocks   = local.github_ipv4
  nessusserver_ip           = var.nessusserver_ip
  nessus_public_access_mode = local.nessus_public_access_mode
  outbound_subnets          = var.outbound_subnets
  proxy_port                = var.proxy_port
  rds_db_port               = var.rds_db_port
  region                    = "us-west-2"
  secondary_cidr_block      = local.network_layout[var.region][var.env_type]._network
  security_group_app_id     = var.apps_enabled == 1 ? aws_security_group.app[0].id : ""
  security_group_idp_id     = aws_security_group.idp.id
  security_group_pivcac_id  = aws_security_group.pivcac.id
  security_group_worker_id  = aws_security_group.worker.id
  vpc_cidr_block            = var.vpc_cidr_block
  cloudwatch_retention_days = local.retention_days
}
