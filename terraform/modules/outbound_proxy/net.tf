data "aws_ip_ranges" "route53" {
  regions  = ["global"]
  services = ["route53"]
}

locals {
  net_ssm_parameter_prefix = "/${var.env_name}/network/"
}

resource "aws_security_group" "obproxy" {
  name_prefix = "${var.name}-obproxy-${var.env_name}"
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

  # need 80/443 to get packages/gems/etc as well as ssm
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
    cidr_blocks = var.github_ipv4_cidr_blocks
  }

  #s3 gateway
  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [var.s3_prefix_list_id]
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
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ci_sg_ssh_cidr_blocks
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.name}-obproxy-${var.env_name}"
    role = "outboundproxy"
  }

  vpc_id = var.vpc_id
}

resource "aws_ssm_parameter" "net_outboundproxy" {
  name  = "${local.net_ssm_parameter_prefix}outboundproxy/url"
  type  = "String"
  value = "http://${var.proxy_server}:${var.proxy_port}"
}

resource "aws_ssm_parameter" "net_noproxy" {
  name  = "${local.net_ssm_parameter_prefix}outboundproxy/no_proxy"
  type  = "String"
  value = var.no_proxy_hosts
}
