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

### Secondary Cidr Attachment and Subnets from Secondary CIDR range###

resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
  vpc_id     = aws_vpc.default.id
  cidr_block = var.secondary_cidr_block
}

### DB Subnets ###

resource "aws_subnet" "data-services" {
  for_each                = var.az
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
  for_each                = var.az
  availability_zone       = "${var.region}${each.key}"
  cidr_block              = each.value.apps.ipv4-cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-app_subnet_${each.key}-${var.env_name}"
  }

  vpc_id = aws_vpc_ipv4_cidr_block_association.secondary_cidr.vpc_id
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
  tags = {
    Name = "${var.env_name}-db"
  }

  vpc_id     = aws_vpc.default.id
  subnet_ids = [for subnet in aws_subnet.data-services : subnet.id]
}

# allow ephemeral ports out
resource "aws_network_acl_rule" "db-egress-s-ephemeral" {
  network_acl_id = aws_network_acl.db.id
  egress         = true
  from_port      = 32768
  to_port        = 61000
  protocol       = "tcp"
  rule_number    = 6
  rule_action    = "allow"
  cidr_block     = var.secondary_cidr_block
}

resource "aws_network_acl_rule" "db-egress-nessus-ephemeral" {
  count          = var.nessus_public_access_mode ? 1 : 0
  network_acl_id = aws_network_acl.db.id
  egress         = true
  from_port      = 32768
  to_port        = 61000
  protocol       = "tcp"
  rule_number    = 7
  rule_action    = "allow"
  cidr_block     = var.nessusserver_ip
}

# let redis in
resource "aws_network_acl_rule" "db-ingress-s-redis" {
  network_acl_id = aws_network_acl.db.id
  egress         = false
  from_port      = 6379
  to_port        = 6379
  protocol       = "tcp"
  rule_number    = 11
  rule_action    = "allow"
  cidr_block     = var.secondary_cidr_block
}

# let postgres in
resource "aws_network_acl_rule" "db-ingress-s-postgres" {
  network_acl_id = aws_network_acl.db.id
  egress         = false
  from_port      = var.rds_db_port
  to_port        = var.rds_db_port
  protocol       = "tcp"
  rule_number    = 16
  rule_action    = "allow"
  cidr_block     = var.secondary_cidr_block
}

resource "aws_network_acl_rule" "db-ingress-nessus-redis" {
  count          = var.nessus_public_access_mode ? 1 : 0
  network_acl_id = aws_network_acl.db.id
  egress         = false
  from_port      = 6379
  to_port        = 6379
  protocol       = "tcp"
  rule_number    = 17
  rule_action    = "allow"
  cidr_block     = var.nessusserver_ip
}

resource "aws_network_acl_rule" "db-ingress-nessus-postgres" {
  count          = var.nessus_public_access_mode ? 1 : 0
  network_acl_id = aws_network_acl.db.id
  egress         = false
  from_port      = var.rds_db_port
  to_port        = var.rds_db_port
  protocol       = "tcp"
  rule_number    = 18
  rule_action    = "allow"
  cidr_block     = var.nessusserver_ip
}

#### NACL for app subnets ###

resource "aws_network_acl" "idp" {
  tags = {
    Name = "${var.env_name}-idp"
  }

  vpc_id     = aws_vpc_ipv4_cidr_block_association.secondary_cidr.vpc_id
  subnet_ids = [for subnet in aws_subnet.app : subnet.id]
}

# Uses up to rule number 25 + number of ssh_cidr_blocks
module "idp-base-nacl-rules" {
  source         = "../../modules/base_nacl_rules"
  network_acl_id = aws_network_acl.idp.id
}

resource "aws_network_acl_rule" "idp-ingress-s-http" {
  network_acl_id = aws_network_acl.idp.id
  egress         = false
  from_port      = 80
  to_port        = 80
  protocol       = "tcp"
  rule_number    = 41
  rule_action    = "allow"
  cidr_block     = var.secondary_cidr_block
}

resource "aws_network_acl_rule" "idp-ingress-s-https" {
  network_acl_id = aws_network_acl.idp.id
  egress         = false
  from_port      = 443
  to_port        = 443
  protocol       = "tcp"
  rule_number    = 49
  rule_action    = "allow"
  cidr_block     = var.secondary_cidr_block
}

resource "aws_network_acl_rule" "idp-ingress-s-proxy" {
  network_acl_id = aws_network_acl.idp.id
  egress         = false
  from_port      = 1024
  to_port        = 65535
  protocol       = "tcp"
  rule_number    = 50
  rule_action    = "allow"
  cidr_block     = var.secondary_cidr_block
}

### DB Subnet Groups ###

resource "aws_db_subnet_group" "aurora" {
  name        = "${var.name}-rds-${var.env_name}"
  description = "RDS Aurora Subnet Group for ${var.env_name} environment"
  subnet_ids  = [for subnet in aws_subnet.data-services : subnet.id]
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
  route_table_ids = [aws_vpc.default.main_route_table_id]
}

### Get vpc flow logs going into cloudwatch ###

resource "aws_flow_log" "flow_log" {
  log_destination = aws_cloudwatch_log_group.flow_log_group.arn
  iam_role_arn    = var.flow_log_iam_role_arn
  vpc_id          = aws_vpc.default.id
  traffic_type    = "ALL"
}

resource "aws_cloudwatch_log_group" "flow_log_group" {
  name = "${var.env_name}_flow_log_group"
}