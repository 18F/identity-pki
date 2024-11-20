locals {
  net_ssm_parameter_prefix = "/${var.env_name}/network/"
  network_layout           = module.network_layout.network_layout
  nessus_public_access_mode = (
    var.root_domain == "analytics.identitysandbox.gov" && var.allow_nessus_external_scanning ?
    true : false
  )
}

module "network_layout" {
  source = "../../modules/network_layout"
}

resource "aws_vpc" "analytics_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name}-vpc-${var.env_name}"
  }
}

resource "aws_flow_log" "flow_log" {
  log_destination = aws_cloudwatch_log_group.flow_log_group.arn
  iam_role_arn    = aws_iam_role.flow_role.arn
  vpc_id          = aws_vpc.analytics_vpc.id
  traffic_type    = "ALL"
}

module "vpc_flow_cloudwatch_filters" {
  source = "github.com/18F/identity-terraform//vpc_flow_cloudwatch_filters?ref=06c8ddd069ed1eea84785033f87b7560eaf0ef6f"
  #source     = "../../../identity-terraform/vpc_flow_cloudwatch_filters"
  depends_on = [aws_flow_log.flow_log]

  env_name      = var.env_name
  alarm_actions = local.low_priority_alarm_actions
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

resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
  vpc_id     = aws_vpc.analytics_vpc.id
  cidr_block = local.network_layout[var.region][var.env_type]._network
}

resource "aws_ssm_parameter" "net_vpcid" {
  name  = "${local.net_ssm_parameter_prefix}vpc/id"
  type  = "String"
  value = aws_vpc.analytics_vpc.id
}

resource "aws_internet_gateway" "analytics_vpc" {
  vpc_id = aws_vpc.analytics_vpc.id

  tags = {
    Name = "${var.name}-gateway-${var.env_name}"
  }
}

resource "aws_route_table" "public" {
  for_each = local.network_zones
  vpc_id   = aws_vpc.analytics_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.analytics_vpc.id
  }

  tags = {
    Name = "${var.name}-public-${each.key}-${var.env_name}"
  }
}

resource "aws_route_table" "private" {
  for_each = local.network_zones
  vpc_id   = aws_vpc.analytics_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.apps[each.key].id
  }

  tags = {
    Name = "${var.name}-private-${each.key}-${var.env_name}"
  }
}

resource "aws_subnet" "apps" {
  for_each                = local.network_zones
  availability_zone       = "${var.region}${each.key}"
  cidr_block              = local.network_layout[var.region][var.env_type]["_zones"][each.key]["apps"]["ipv4-cidr"]
  depends_on              = [aws_internet_gateway.analytics_vpc]
  map_public_ip_on_launch = false

  ## Example Enablement of IPv6 for app subnets.
  # ipv6_cidr_block = cidrsubnet(aws_vpc.analytics_vpc.ipv6_cidr_block, 8, local.network_layout[var.region][var.env_type]["_zones"][each.key]["apps"]["ipv6-netnum"])

  tags = {
    Name = "${var.name}-apps-subnet-${each.key}-${var.env_name}"
  }

  vpc_id = aws_vpc_ipv4_cidr_block_association.secondary_cidr.vpc_id
}

resource "aws_eip" "apps" {
  for_each = local.network_zones
  domain   = "vpc"
}

resource "aws_nat_gateway" "apps" {
  for_each      = local.network_zones
  subnet_id     = aws_subnet.public-ingress[each.key].id
  allocation_id = aws_eip.apps[each.key].id
  tags = {
    Name = "${var.name}-public-nat-gw-${each.key}-${var.env_name}"
  }
}

resource "aws_route_table_association" "apps_subnet_route_table_association" {
  for_each       = local.network_zones
  route_table_id = aws_route_table.private[each.key].id
  subnet_id      = aws_subnet.apps[each.key].id
}

resource "aws_subnet" "data-services" {
  for_each                = local.network_zones
  availability_zone       = "${var.region}${each.key}"
  cidr_block              = local.network_layout[var.region][var.env_type]["_zones"][each.key]["data-services"]["ipv4-cidr"]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name}-data-services-subnet-${each.key}-${var.env_name}"
  }

  vpc_id = aws_vpc_ipv4_cidr_block_association.secondary_cidr.vpc_id
}

resource "aws_route_table_association" "data_services_subnet_route_table_association" {
  for_each       = local.network_zones
  route_table_id = aws_route_table.public[each.key].id
  subnet_id      = aws_subnet.data-services[each.key].id
}

resource "aws_subnet" "public-ingress" {
  for_each                = local.network_zones
  availability_zone       = "${var.region}${each.key}"
  cidr_block              = local.network_layout[var.region][var.env_type]["_zones"][each.key]["public-ingress"]["ipv4-cidr"]
  map_public_ip_on_launch = false

  #ipv6_cidr_block = cidrsubnet(aws_vpc.analytics_vpc.ipv6_cidr_block, 8, local.network_layout[var.region][var.env_type]["_zones"][each.key]["public-ingress"]["ipv6-netnum"])

  tags = {
    Name = "${var.name}-public-ingress-subnet-${each.key}-${var.env_name}"
  }

  vpc_id = aws_vpc_ipv4_cidr_block_association.secondary_cidr.vpc_id
}

resource "aws_route_table_association" "public_ingress_subnet_route_table_association" {
  for_each       = local.network_zones
  route_table_id = aws_route_table.public[each.key].id
  subnet_id      = aws_subnet.public-ingress[each.key].id
}

resource "aws_subnet" "endpoints" {
  for_each                = local.network_zones
  availability_zone       = "${var.region}${each.key}"
  cidr_block              = local.network_layout[var.region][var.env_type]["_zones"][each.key]["endpoints"]["ipv4-cidr"]
  map_public_ip_on_launch = false

  #ipv6_cidr_block = cidrsubnet(aws_vpc.analytics_vpc.ipv6_cidr_block, 8, local.network_layout[var.region][var.env_type]["_zones"][each.key]["apps"]["ipv6-netnum"])

  tags = {
    Name = "${var.name}-public-endpoints-subnet-${each.key}-${var.env_name}"
  }

  vpc_id = aws_vpc_ipv4_cidr_block_association.secondary_cidr.vpc_id
}

resource "aws_route_table_association" "endpoints_subnet_route_table_association" {
  for_each       = local.network_zones
  route_table_id = aws_route_table.public[each.key].id
  subnet_id      = aws_subnet.endpoints[each.key].id
}

resource "aws_redshift_subnet_group" "redshift_subnet_group" {
  name       = "${var.env_name}-redshift-subnet-group"
  subnet_ids = [for subnet in aws_subnet.data-services : subnet.id]

  tags = {
    environment = var.env_name
  }
}

resource "aws_subnet" "lambda_subnet" {
  cidr_block = cidrsubnet(aws_vpc.analytics_vpc.cidr_block, 8, 2)
  vpc_id     = aws_vpc.analytics_vpc.id

  tags = {
    Name = "${var.env_name}-lambda-subnet"
  }
}
