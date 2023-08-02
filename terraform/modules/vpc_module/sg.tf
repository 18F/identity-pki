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