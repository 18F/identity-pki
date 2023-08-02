resource "aws_security_group" "endpoint" {
  for_each    = var.aws_services
  description = "Allow inbound from all servers"

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    security_groups = [
      aws_security_group.base.id
    ]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for subnet in aws_subnet.app : subnet.cidr_block]
  }

  dynamic "egress" {
    for_each = each.value["vpc_cidr_egress"] == true ? [1] : []
    content {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      cidr_blocks = [var.secondary_cidr_block]
    }
  }

  name = "${var.name}-${each.key}-endpoint-${var.env_name}"

  tags = {
    Name = "${var.name}-${each.key}-endpoint-${var.env_name}"
  }

  vpc_id = aws_vpc.default.id

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_vpc_endpoint_service" "service" {
  for_each = var.aws_services
  service  = each.key
}

resource "aws_vpc_endpoint" "service" {
  for_each = var.aws_services

  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.${each.key}"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.endpoint[each.key].id,
  ]

  subnet_ids = [for subnet in aws_subnet.app : subnet.id if contains(
    data.aws_vpc_endpoint_service.service[each.key].availability_zones,
    subnet.availability_zone
  )]

  private_dns_enabled = true

  lifecycle {
    create_before_destroy = true
  }
}