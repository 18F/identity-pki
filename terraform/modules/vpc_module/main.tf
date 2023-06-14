data "aws_vpc" "default_vpc" {
  id = aws_vpc.default.id
}

data "aws_subnet" "db_subnets" {
  for_each = aws_subnet.data-services
  id       = each.value.id
}

data "aws_subnet" "app" {
  for_each = aws_subnet.app
  id       = each.value.id
}

### VPC ###
resource "aws_vpc" "default" {
  cidr_block = var.vpc_cidr_block

  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true

  tags = {
    Name = "${var.name}-vpc-${var.env_name}"
  }
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

resource "aws_ssm_parameter" "net_vpcid" {
  name  = var.vpc_ssm_parameter_prefix
  type  = "String"
  value = aws_vpc.default.id
}

### Secondary Cidr Attachment and Subnets from Secondary CIDR range###

resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
  vpc_id     = aws_vpc.default.id
  cidr_block = var.secondary_cidr_block
}

### DB Subnets ###

resource "aws_subnet" "data-services" {
  for_each                = var.enable_data_services ? var.az : {}
  availability_zone       = "${var.region}${each.key}"
  cidr_block              = each.value.data-services.ipv4-cidr
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name}-data_services_subnet_${each.key}-${var.env_name}"
  }

  vpc_id = aws_vpc_ipv4_cidr_block_association.secondary_cidr.vpc_id
}

### App Subnets ###

resource "aws_subnet" "app" {
  for_each                = var.enable_app ? var.az : {}
  availability_zone       = "${var.region}${each.key}"
  cidr_block              = each.value.apps.ipv4-cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-app_subnet_${each.key}-${var.env_name}"
  }

  vpc_id = aws_vpc_ipv4_cidr_block_association.secondary_cidr.vpc_id
}

### Route Table for DB Subnets ###

resource "aws_route_table" "database" {
  count = var.enable_data_services ? 1 : 0

  vpc_id = aws_vpc_ipv4_cidr_block_association.secondary_cidr.vpc_id
}

resource "aws_route_table_association" "database" {
  for_each       = aws_subnet.data-services
  route_table_id = aws_route_table.database[0].id
  subnet_id      = each.value.id
}

### Route Table for App Subnets ###

resource "aws_route_table" "app" {
  count = var.enable_app ? 1 : 0

  vpc_id = aws_vpc_ipv4_cidr_block_association.secondary_cidr.vpc_id
}

resource "aws_route_table_association" "app" {
  for_each       = aws_subnet.app
  route_table_id = aws_route_table.app[0].id
  subnet_id      = each.value.id
}

#### Default NACL ###

resource "aws_default_network_acl" "default" {
  default_network_acl_id = aws_vpc.default.default_network_acl_id

  tags = {
    Name = "${var.env_name}-default-should-not-be-used"
  }

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

#### NACL for db subnets ###

resource "aws_network_acl" "db" {
  count = var.enable_data_services ? 1 : 0
  tags = {
    Name = "${var.env_name}-db"
  }

  vpc_id     = aws_vpc.default.id
  subnet_ids = [for subnet in aws_subnet.data-services : subnet.id]
}

resource "aws_network_acl_rule" "db_inbound" {
  count          = var.enable_data_services ? length(var.db_inbound_acl_rules) : 0
  network_acl_id = aws_network_acl.db[0].id

  egress          = false
  rule_number     = var.db_inbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.db_inbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.db_inbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.db_inbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.db_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.db_inbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.db_inbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.db_inbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.db_inbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

resource "aws_network_acl_rule" "db_outbound" {
  count          = var.enable_data_services ? length(var.db_outbound_acl_rules) : 0
  network_acl_id = aws_network_acl.db[0].id

  egress          = true
  rule_number     = var.db_outbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.db_outbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.db_outbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.db_outbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.db_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.db_outbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.db_outbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.db_outbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.db_outbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

#### NACL for app subnets ###

resource "aws_network_acl" "idp" {
  count = var.enable_app ? 1 : 0
  tags = {
    Name = "${var.env_name}-idp"
  }

  vpc_id     = aws_vpc_ipv4_cidr_block_association.secondary_cidr.vpc_id
  subnet_ids = [for subnet in aws_subnet.app : subnet.id]
}

resource "aws_network_acl_rule" "app_inbound" {
  count          = var.enable_app ? length(var.app_inbound_acl_rules) : 0
  network_acl_id = aws_network_acl.idp[0].id

  egress          = false
  rule_number     = var.app_inbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.app_inbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.app_inbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.app_inbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.app_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.app_inbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.app_inbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.app_inbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.app_inbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

resource "aws_network_acl_rule" "app_outbound" {
  count          = var.enable_app ? length(var.app_outbound_acl_rules) : 0
  network_acl_id = aws_network_acl.idp[0].id

  egress          = true
  rule_number     = var.app_outbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.app_outbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.app_outbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.app_outbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.app_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.app_outbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.app_outbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.app_outbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.app_outbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

### DB Subnet Groups ###

resource "aws_db_subnet_group" "aurora" {
  count       = var.enable_data_services ? 1 : 0
  name        = "${var.name}-rds-${var.env_name}"
  description = "RDS Aurora Subnet Group for ${var.env_name} environment"
  subnet_ids  = [for subnet in aws_subnet.data-services : subnet.id]
}

### DB Security Group ###

resource "aws_security_group" "db" {
  count       = var.enable_data_services ? 1 : 0
  description = "Allow inbound and outbound postgresql traffic with app subnet in vpc"
  vpc_id      = aws_vpc.default.id
  name        = "${var.name}-db-${var.env_name}"

  dynamic "ingress" {
    for_each = var.db_security_group_ingress
    content {
      self             = lookup(ingress.value, "self", null)
      cidr_blocks      = compact(split(",", lookup(ingress.value, "cidr_blocks", "")))
      ipv6_cidr_blocks = compact(split(",", lookup(ingress.value, "ipv6_cidr_blocks", "")))
      prefix_list_ids  = compact(split(",", lookup(ingress.value, "prefix_list_ids", "")))
      security_groups  = compact(split(",", lookup(ingress.value, "security_groups", "")))
      description      = lookup(ingress.value, "description", null)
      from_port        = lookup(ingress.value, "from_port", 0)
      to_port          = lookup(ingress.value, "to_port", 0)
      protocol         = lookup(ingress.value, "protocol", "-1")
    }
  }

  dynamic "egress" {
    for_each = var.db_security_group_egress
    content {
      self             = lookup(egress.value, "self", null)
      cidr_blocks      = compact(split(",", lookup(egress.value, "cidr_blocks", "")))
      ipv6_cidr_blocks = compact(split(",", lookup(egress.value, "ipv6_cidr_blocks", "")))
      prefix_list_ids  = compact(split(",", lookup(egress.value, "prefix_list_ids", "")))
      security_groups  = compact(split(",", lookup(egress.value, "security_groups", "")))
      description      = lookup(egress.value, "description", null)
      from_port        = lookup(egress.value, "from_port", 0)
      to_port          = lookup(egress.value, "to_port", 0)
      protocol         = lookup(egress.value, "protocol", "-1")
    }
  }
  tags = {
    Name = "${var.name}-db_security_group-${var.env_name}"
  }
}

### App Security Group ###

resource "aws_security_group" "app" {
  count       = var.enable_app ? 1 : 0
  description = "Security group for sample app servers"

  vpc_id = aws_vpc_ipv4_cidr_block_association.secondary_cidr.vpc_id

  dynamic "ingress" {
    for_each = var.app_security_group_ingress
    content {
      self             = lookup(ingress.value, "self", null)
      cidr_blocks      = compact(split(",", lookup(ingress.value, "cidr_blocks", "")))
      ipv6_cidr_blocks = compact(split(",", lookup(ingress.value, "ipv6_cidr_blocks", "")))
      prefix_list_ids  = compact(split(",", lookup(ingress.value, "prefix_list_ids", "")))
      security_groups  = compact(split(",", lookup(ingress.value, "security_groups", "")))
      description      = lookup(ingress.value, "description", null)
      from_port        = lookup(ingress.value, "from_port", 0)
      to_port          = lookup(ingress.value, "to_port", 0)
      protocol         = lookup(ingress.value, "protocol", "-1")
    }
  }

  dynamic "egress" {
    for_each = var.app_security_group_egress
    content {
      self             = lookup(egress.value, "self", null)
      cidr_blocks      = compact(split(",", lookup(egress.value, "cidr_blocks", "")))
      ipv6_cidr_blocks = compact(split(",", lookup(egress.value, "ipv6_cidr_blocks", "")))
      prefix_list_ids  = compact(split(",", lookup(egress.value, "prefix_list_ids", "")))
      security_groups  = compact(split(",", lookup(egress.value, "security_groups", "")))
      description      = lookup(egress.value, "description", null)
      from_port        = lookup(egress.value, "from_port", 0)
      to_port          = lookup(egress.value, "to_port", 0)
      protocol         = lookup(egress.value, "protocol", "-1")
    }
  }
  name = "${var.env_name}-app"

  tags = {
    Name = "${var.name}-app_security_group-${var.env_name}"
    role = "app"
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

### S3 Gateway endpoint ###

resource "aws_vpc_endpoint" "private-s3" {
  vpc_id          = aws_vpc_ipv4_cidr_block_association.secondary_cidr.vpc_id
  service_name    = "com.amazonaws.${var.region}.s3"
  route_table_ids = [aws_route_table.database[0].id, aws_route_table.app[0].id]
}

### Get vpc flow logs going into cloudwatch ###

resource "aws_flow_log" "flow_log" {
  log_destination = aws_cloudwatch_log_group.flow_log_group.arn
  #iam_role_arn    = module.application_iam_roles.flow_role_iam_role_arn
  iam_role_arn = var.flow_log_iam_role_arn
  vpc_id       = aws_vpc.default.id
  traffic_type = "ALL"
}

resource "aws_cloudwatch_log_group" "flow_log_group" {
  name = "${var.env_name}_flow_log_group"
}