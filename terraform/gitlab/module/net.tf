data "aws_ip_ranges" "route53" {
  regions  = ["global"]
  services = ["route53"]
}

locals {
  net_ssm_parameter_prefix = "/${var.env_name}/network/"
}

module "outbound_proxy" {
  source = "../../modules/outbound_proxy"

  account_default_ami_id           = var.default_ami_id_tooling
  ami_id_map                       = var.ami_id_map
  base_security_group_id           = aws_security_group.base.id
  bootstrap_main_git_ref_default   = local.bootstrap_main_git_ref_default
  bootstrap_main_s3_ssh_key_url    = local.bootstrap_main_s3_ssh_key_url
  bootstrap_private_s3_ssh_key_url = local.bootstrap_private_s3_ssh_key_url
  env_name                         = var.env_name
  public_subnets                   = [aws_subnet.publicsubnet1.id, aws_subnet.publicsubnet2.id, aws_subnet.publicsubnet3.id]
  route53_internal_zone_id         = aws_route53_zone.internal.zone_id
  s3_prefix_list_id                = aws_vpc_endpoint.private-s3.prefix_list_id
  slack_events_sns_hook_arn        = var.slack_events_sns_hook_arn
  vpc_id                           = aws_vpc.default.id
  github_ipv4_cidr_blocks          = local.github_ipv4_cidr_blocks
  root_domain                      = var.root_domain
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
  name  = "${local.net_ssm_parameter_prefix}vpc/id"
  type  = "String"
  value = aws_vpc.default.id
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
    security_groups = [module.outbound_proxy.proxy_security_group_id]
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

  lifecycle {
    create_before_destroy = true
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

  lifecycle {
    create_before_destroy = true
  }
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

  # need 8834 to comm with Nessus Server
  egress {
    from_port   = 8834
    to_port     = 8834
    protocol    = "tcp"
    cidr_blocks = [var.nessusserver_ip]
  }

  # TODO: Can we use HTTPS for provisioning instead?
  # github
  egress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    # github
    cidr_blocks = local.github_ipv4_cidr_blocks
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.gitlab-lb.id]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.gitlab-lb.id]
  }

  name_prefix = "${var.name}-gitlab-${var.env_name}"

  tags = {
    Name = "${var.name}-gitlabserver_security_group-${var.env_name}"
    role = "gitlab"
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group" "gitlab-lb" {
  description = "Allow inbound gitlab traffic from allowlisted IPs"

  # TODO: limit this to what is actually needed
  # allow outbound to the VPC so that we can get to db/redis/logstash/etc.
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_gitlab_cidr_blocks_v4
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_gitlab_cidr_blocks_v4
  }

  # these are the EIPs for the NAT which is being used by the obproxies
  # This is needed so that the outbound proxies can access the external lb.
  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [
      "${aws_eip.nat_a.public_ip}/32",
      "${aws_eip.nat_b.public_ip}/32",
      "${aws_eip.nat_c.public_ip}/32"
    ]
  }

  name_prefix = "${var.name}-gitlab-lb-${var.env_name}"

  tags = {
    Name = "${var.name}-gitlab-lb_security_group-${var.env_name}"
  }

  lifecycle {
    create_before_destroy = true
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
    name = "${var.name}-alb2_subnet-${var.env_name}"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_subnet" "alb3" {
  availability_zone       = "${var.region}c"
  cidr_block              = var.alb3_subnet_cidr_block
  depends_on              = [aws_internet_gateway.default]
  map_public_ip_on_launch = true

  tags = {
    name = "${var.name}-alb3_subnet-${var.env_name}"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_vpc_endpoint" "private-s3" {
  vpc_id          = aws_vpc.default.id
  service_name    = "com.amazonaws.${var.region}.s3"
  route_table_ids = [aws_vpc.default.main_route_table_id]
}

# create NAT subnets and gateways
resource "aws_subnet" "nat_a" {
  availability_zone       = "${var.region}a"
  cidr_block              = var.nat_a_subnet_cidr_block
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name}-nat_a_subnet-${var.env_name}"
    type = "public"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_eip" "nat_a" {
  vpc = true
}

resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.nat_a.id

  tags = {
    Name = "${var.env_name}-nat_a"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.default]
}

resource "aws_route_table" "nat_a" {
  vpc_id = aws_vpc.default.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }

  tags = {
    Name = "${var.env_name} nat_a"
  }
}

resource "aws_route_table_association" "nat_a" {
  subnet_id      = aws_subnet.nat_a.id
  route_table_id = aws_route_table.nat_a.id
}

resource "aws_subnet" "nat_b" {
  availability_zone       = "${var.region}b"
  cidr_block              = var.nat_b_subnet_cidr_block
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name}-nat_b_subnet-${var.env_name}"
    type = "public"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_eip" "nat_b" {
  vpc = true
}

resource "aws_nat_gateway" "nat_b" {
  allocation_id = aws_eip.nat_b.id
  subnet_id     = aws_subnet.nat_b.id

  tags = {
    Name = "${var.env_name}-nat_b"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.default]
}

resource "aws_route_table" "nat_b" {
  vpc_id = aws_vpc.default.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }

  tags = {
    Name = "${var.env_name} nat_b"
  }
}

resource "aws_route_table_association" "nat_b" {
  subnet_id      = aws_subnet.nat_b.id
  route_table_id = aws_route_table.nat_b.id
}

resource "aws_subnet" "nat_c" {
  availability_zone       = "${var.region}c"
  cidr_block              = var.nat_c_subnet_cidr_block
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name}-nat_c_subnet-${var.env_name}"
    type = "public"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_eip" "nat_c" {
  vpc = true
}

resource "aws_nat_gateway" "nat_c" {
  allocation_id = aws_eip.nat_c.id
  subnet_id     = aws_subnet.nat_c.id

  tags = {
    Name = "${var.env_name}-nat_c"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.default]
}

resource "aws_route_table" "nat_c" {
  vpc_id = aws_vpc.default.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }

  tags = {
    Name = "${var.env_name} nat_c"
  }
}

resource "aws_route_table_association" "nat_c" {
  subnet_id      = aws_subnet.nat_c.id
  route_table_id = aws_route_table.nat_c.id
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

resource "aws_route_table" "publicsubnet1" {
  vpc_id = aws_vpc.default.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }

  tags = {
    Name = "${var.env_name}-publicsubnet1"
  }
}

resource "aws_route_table_association" "publicsubnet1" {
  subnet_id      = aws_subnet.publicsubnet1.id
  route_table_id = aws_route_table.publicsubnet1.id
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

resource "aws_route_table" "publicsubnet2" {
  vpc_id = aws_vpc.default.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_b.id
  }

  tags = {
    Name = "${var.env_name}-publicsubnet2"
  }
}

resource "aws_route_table_association" "publicsubnet2" {
  subnet_id      = aws_subnet.publicsubnet2.id
  route_table_id = aws_route_table.publicsubnet2.id
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

resource "aws_route_table" "publicsubnet3" {
  vpc_id = aws_vpc.default.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_c.id
  }

  tags = {
    Name = "${var.env_name}-publicsubnet3"
  }
}

resource "aws_route_table_association" "publicsubnet3" {
  subnet_id      = aws_subnet.publicsubnet3.id
  route_table_id = aws_route_table.publicsubnet3.id
}

resource "aws_subnet" "privatesubnet1" {
  availability_zone       = "${var.region}a"
  cidr_block              = var.private1_subnet_cidr_block
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-private1_subnet-${var.env_name}"
    type = "private"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_ssm_parameter" "net_subnet_private1" {
  name  = "${local.net_ssm_parameter_prefix}subnet/private1/id"
  type  = "String"
  value = aws_subnet.privatesubnet1.id
}

resource "aws_subnet" "privatesubnet2" {
  availability_zone       = "${var.region}b"
  cidr_block              = var.private2_subnet_cidr_block
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-private2_subnet-${var.env_name}"
    type = "private"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_ssm_parameter" "net_subnet_private2" {
  name  = "${local.net_ssm_parameter_prefix}subnet/private2/id"
  type  = "String"
  value = aws_subnet.privatesubnet2.id
}

resource "aws_subnet" "privatesubnet3" {
  availability_zone       = "${var.region}c"
  cidr_block              = var.private3_subnet_cidr_block
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-private3_subnet-${var.env_name}"
    type = "private"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_ssm_parameter" "net_subnet_private3" {
  name  = "${local.net_ssm_parameter_prefix}subnet/private3/id"
  type  = "String"
  value = aws_subnet.privatesubnet3.id
}

resource "aws_security_group" "cache" {
  description = "Allow inbound and outbound redis traffic with app subnet in vpc"

  egress {
    from_port = 6379
    to_port   = 6379
    protocol  = "tcp"
    security_groups = [
      aws_security_group.gitlab.id,
    ]
  }

  ingress {
    from_port = 6379
    to_port   = 6379
    protocol  = "tcp"
    security_groups = [
      aws_security_group.gitlab.id,
    ]
  }

  name_prefix = "${var.name}-cache-${var.env_name}"

  tags = {
    Name = "${var.name}-cache_security_group-${var.env_name}"
  }

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_elasticache_subnet_group" "gitlab" {
  name        = "${var.name}-gitlab-cache-${var.env_name}"
  description = "Redis Subnet Group"
  subnet_ids  = [aws_subnet.db1.id, aws_subnet.db2.id]
}
