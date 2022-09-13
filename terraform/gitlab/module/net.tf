data "aws_ip_ranges" "route53" {
  regions  = ["global"]
  services = ["route53"]
}

locals {
  net_ssm_parameter_prefix = "/${var.env_name}/network/"
  network_layout           = module.network_layout.network_layout
}

module "network_layout" {
  source = "../../modules/network_layout"
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

resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
  vpc_id     = aws_vpc.default.id
  cidr_block = local.network_layout[var.region][var.env_type]._network
}

resource "aws_ssm_parameter" "net_vpcid" {
  name  = "${local.net_ssm_parameter_prefix}vpc/id"
  type  = "String"
  value = aws_vpc.default.id
}

resource "aws_internet_gateway" "default" {
  tags = {
    Name = "${var.name}-gateway-${var.env_name}"
  }
  vpc_id = aws_vpc.default.id
}

## Start - Create EIP for NAT Gateway

resource "aws_eip" "public_ingress_nat_gw_eip" {
  for_each = local.network_zones
}

## End - Create EIP for NAT Gateway

## Start - Create NAT Gateways in login-ingress-public subnets
resource "aws_nat_gateway" "nat" {
  for_each      = local.network_zones
  allocation_id = aws_eip.public_ingress_nat_gw_eip[each.key].id
  subnet_id     = aws_subnet.public-ingress[each.key].id
  tags = {
    Name = "${var.name}-nat_gateway_${each.key}-${var.env_name}"
  }
}

## End - Create NAT Gateways in login-public subnets


resource "aws_route_table" "private_subnet_route_table" {
  for_each = local.network_zones
  vpc_id   = aws_vpc.default.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[each.key].id
  }

  tags = {
    Name = "${var.name}-private_subnet_route_table_${each.key}-${var.env_name}"
  }
}

resource "aws_route_table" "public_subnet_route_table" {
  for_each = local.network_zones
  vpc_id   = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }

  tags = {
    Name = "${var.name}-public_subnet_route_table_${each.key}-${var.env_name}"
  }
}

resource "aws_subnet" "apps" {
  for_each                = local.network_zones
  availability_zone       = "${var.region}${each.key}"
  cidr_block              = local.network_layout[var.region][var.env_type]["_zones"][each.key]["apps"]["ipv4-cidr"]
  depends_on              = [aws_internet_gateway.default]
  map_public_ip_on_launch = false

  ## Example Enablement of IPv6 for app subnets.
  # ipv6_cidr_block = cidrsubnet(aws_vpc.default.ipv6_cidr_block, 8, local.network_layout[var.region][var.env_type]["_zones"][each.key]["apps"]["ipv6-netnum"])

  tags = {
    Name = "${var.name}-apps_subnet_${each.key}-${var.env_name}"
  }

  vpc_id = aws_vpc_ipv4_cidr_block_association.secondary_cidr.vpc_id
}

resource "aws_route_table_association" "apps_subnet_route_table_association" {
  for_each       = local.network_zones
  route_table_id = aws_route_table.private_subnet_route_table[each.key].id
  subnet_id      = aws_subnet.apps[each.key].id
}

resource "aws_subnet" "data-services" {
  for_each                = local.network_zones
  availability_zone       = "${var.region}${each.key}"
  cidr_block              = local.network_layout[var.region][var.env_type]["_zones"][each.key]["data-services"]["ipv4-cidr"]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name}-data_services_subnet_${each.key}-${var.env_name}"
  }

  vpc_id = aws_vpc_ipv4_cidr_block_association.secondary_cidr.vpc_id
}

resource "aws_route_table_association" "data_services_subnet_route_table_association" {
  for_each       = local.network_zones
  route_table_id = aws_route_table.private_subnet_route_table[each.key].id
  subnet_id      = aws_subnet.data-services[each.key].id
}

resource "aws_subnet" "public-ingress" {
  for_each                = local.network_zones
  availability_zone       = "${var.region}${each.key}"
  cidr_block              = local.network_layout[var.region][var.env_type]["_zones"][each.key]["public-ingress"]["ipv4-cidr"]
  map_public_ip_on_launch = true

  ipv6_cidr_block = cidrsubnet(aws_vpc.default.ipv6_cidr_block, 8, local.network_layout[var.region][var.env_type]["_zones"][each.key]["public-ingress"]["ipv6-netnum"])

  tags = {
    Name = "${var.name}-public_ingress_subnet_${each.key}-${var.env_name}"
  }

  vpc_id = aws_vpc_ipv4_cidr_block_association.secondary_cidr.vpc_id
}

resource "aws_route_table_association" "public_ingress_subnet_route_table_association" {
  for_each       = local.network_zones
  route_table_id = aws_route_table.public_subnet_route_table[each.key].id
  subnet_id      = aws_subnet.public-ingress[each.key].id
}

resource "aws_subnet" "endpoints" {
  for_each                = local.network_zones
  availability_zone       = "${var.region}${each.key}"
  cidr_block              = local.network_layout[var.region][var.env_type]["_zones"][each.key]["endpoints"]["ipv4-cidr"]
  map_public_ip_on_launch = false

  ipv6_cidr_block = cidrsubnet(aws_vpc.default.ipv6_cidr_block, 8, local.network_layout[var.region][var.env_type]["_zones"][each.key]["apps"]["ipv6-netnum"])

  tags = {
    Name = "${var.name}-public_endpoints_subnet_${each.key}-${var.env_name}"
  }

  vpc_id = aws_vpc_ipv4_cidr_block_association.secondary_cidr.vpc_id
}

resource "aws_route_table_association" "endpoints_subnet_route_table_association" {
  for_each       = local.network_zones
  route_table_id = aws_route_table.private_subnet_route_table[each.key].id
  subnet_id      = aws_subnet.endpoints[each.key].id
}
