# use instead of 0.0.0.0/0 in ALB security group rules
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
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

### App Security Group ###

resource "aws_security_group" "app" {
  count       = var.apps_enabled
  description = "Security group for sample app servers"

  vpc_id = aws_vpc.default.id

  # TODO: limit this to what is actually needed
  # allow outbound to the VPC so that we can get to db/redis/logstash/etc.
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.secondary_cidr_block]
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
    cidr_blocks = var.github_ipv4_cidr_blocks
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

### DB Security Group ###

resource "aws_security_group" "db" {
  description = "Allow inbound and outbound postgresql traffic with app subnet in vpc"
  vpc_id      = aws_vpc.default.id
  name        = "${var.name}-db-${var.env_name}"

  egress = []

  ingress {
    from_port = var.rds_db_port
    to_port   = var.rds_db_port
    protocol  = "tcp"
    security_groups = compact([
      var.security_group_idp_id,
      aws_security_group.migration.id,
      var.security_group_pivcac_id,
      var.security_group_worker_id,
      var.apps_enabled == 1 ? aws_security_group.app[0].id : ""
    ])
  }

  dynamic "ingress" {
    for_each = var.nessus_public_access_mode ? [1] : []
    content {
      description = "Inbound Nessus Scanning"
      from_port   = var.rds_db_port
      to_port     = var.rds_db_port
      protocol    = "tcp"
      cidr_blocks = [var.nessusserver_ip]
    }
  }

  tags = {
    Name = "${var.name}-db_security_group-${var.env_name}"
  }
}

### Migration Security Group ###

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
    cidr_blocks = [var.secondary_cidr_block]
  }

  # github
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.github_ipv4_cidr_blocks
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
    security_groups = [module.outboundproxy_net.security_group_id]
  }

  # allow ICMP to/from the whole VPC
  ingress {
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = [var.secondary_cidr_block]
  }
  egress {
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = [var.secondary_cidr_block]
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
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  }

  name = "${var.env_name}-app-alb"

  tags = {
    Name = "${var.env_name}-app-alb"
  }
}

module "outboundproxy_net" {
  source = "../../modules/outbound_proxy_net"

  use_prefix              = false
  env_name                = var.env_name
  name                    = var.name
  region                  = var.region
  vpc_cidr_block          = var.secondary_cidr_block
  app_cidr_block          = ""
  vpc_id                  = aws_vpc.default.id
  s3_prefix_list_id       = aws_vpc_endpoint.private-s3.prefix_list_id
  fisma_tag               = var.fisma_tag
  nessusserver_ip         = var.nessusserver_ip
  github_ipv4_cidr_blocks = var.github_ipv4_cidr_blocks
}