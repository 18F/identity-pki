data "aws_ip_ranges" "route53" {
  regions  = ["global"]
  services = ["route53"]
}

locals {
  net_ssm_parameter_prefix  = "/${var.env_name}/network/"
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

  # allow SSH in from gitlab
  ingress {
    description     = "allow SSH in from gitlab"
    protocol        = "tcp"
    from_port       = 22
    to_port         = 22
    security_groups = [aws_security_group.gitlab.id]
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

resource "aws_security_group" "gitlab" {
  description = "Allow inbound gitlab traffic: whitelisted IPs for SSH"

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
    cidr_blocks = data.github_ip_ranges.ips.git
  }

  # TODO split out ELB security group from gitlab SG
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

  # locust distributed
  egress {
    from_port = 5557

    to_port  = 5557
    protocol = "tcp"
    self     = true
  }

  # locust distributed
  ingress {
    from_port = 5557

    to_port  = 5557
    protocol = "tcp"
    self     = true
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
  }

  # need 8834 to comm with Nessus Server
  ingress {
    from_port   = 8834
    to_port     = 8834
    protocol    = "tcp"
    cidr_blocks = [var.nessusserver_ip]
  }

  name = "${var.name}-gitlab-${var.env_name}"

  tags = {
    Name = "${var.name}-gitlab_security_group-${var.env_name}"
    role = "gitlab"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_subnet" "gitlab1" {
  availability_zone       = "${var.region}a"
  cidr_block              = var.gitlab1_subnet_cidr_block
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-gitlab1_subnet-${var.env_name}"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_subnet" "gitlab2" {
  availability_zone       = "${var.region}b"
  cidr_block              = var.gitlab2_subnet_cidr_block
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-gitlab2_subnet-${var.env_name}"
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

resource "aws_subnet" "alb3" {
  availability_zone       = "${var.region}c"
  cidr_block              = var.alb3_subnet_cidr_block
  depends_on              = [aws_internet_gateway.default]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-alb3_subnet-${var.env_name}"
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

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name}-vpc-${var.env_name}"
  }
}

resource "aws_ssm_parameter" "net_vpcid" {
  name = "${local.net_ssm_parameter_prefix}vpc/id"
  type  = "String"
  value = aws_vpc.default.id
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
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-private1_subnet-${var.env_name}"
    type = "private"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_ssm_parameter" "net_subnet_private1" {
  name = "${local.net_ssm_parameter_prefix}subnet/private1/id"
  type  = "String"
  value = aws_subnet.privatesubnet1.id
}

resource "aws_subnet" "privatesubnet2" {
  availability_zone = "${var.region}b"
  cidr_block        = var.private2_subnet_cidr_block
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-private2_subnet-${var.env_name}"
    type = "private"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_ssm_parameter" "net_subnet_private2" {
  name = "${local.net_ssm_parameter_prefix}subnet/private2/id"
  type  = "String"
  value = aws_subnet.privatesubnet2.id
}

resource "aws_subnet" "privatesubnet3" {
  availability_zone = "${var.region}c"
  cidr_block        = var.private3_subnet_cidr_block
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-private3_subnet-${var.env_name}"
    type = "private"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_ssm_parameter" "net_subnet_private3" {
  name = "${local.net_ssm_parameter_prefix}subnet/private3/id"
  type  = "String"
  value = aws_subnet.privatesubnet3.id
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
    cidr_blocks = data.github_ip_ranges.ips.git
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

resource "aws_ssm_parameter" "net_outboundproxy" {
  name = "${local.net_ssm_parameter_prefix}outboundproxy/url"
  type  = "String"
  value = "http://${var.proxy_server}:${var.proxy_port}"
}

resource "aws_ssm_parameter" "net_noproxy" {
  name = "${local.net_ssm_parameter_prefix}outboundproxy/no_proxy"
  type  = "String"
  value = var.no_proxy_hosts
}
