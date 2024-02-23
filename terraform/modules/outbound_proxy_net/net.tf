resource "aws_security_group" "obproxy" {
  name        = var.use_prefix ? null : "${var.name}-obproxy-${var.env_name}"
  name_prefix = var.use_prefix ? "${var.name}-obproxy-${var.env_name}" : null
  description = "Allow inbound web traffic and whitelisted IP(s) for SSH"

  # TODO: limit this to what is actually needed
  egress {
    description = "allow outbound to the VPC so that we can get to db/redis/logstash/etc."
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    description = "need 80/443 to get packages/gems/etc"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "need 80/443 to get packages/gems/etc as well as ssm"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "allow github access to their static cidr block"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.github_ipv4_cidr_blocks
  }

  egress {
    description     = "s3 gateway"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [var.s3_prefix_list_id]
  }

  egress {
    description = "need 8834 to comm with Nessus Server"
    from_port   = 8834
    to_port     = 8834
    protocol    = "tcp"
    cidr_blocks = [var.nessusserver_ip]
  }

  egress {
    description = "Allow egress to GSA Public Bigfix Relay Server"
    from_port   = 52311
    to_port     = 52311
    protocol    = "tcp"
    cidr_blocks = [
      "3.209.219.136/32"
    ]
  }

  egress {
    description = "Allow egress to AAMVA"
    from_port   = 18449
    to_port     = 18449
    protocol    = "tcp"
    cidr_blocks = [
      "66.227.17.192/26",
      "66.16.0.0/16",
      "66.192.89.112/32",
      "66.192.89.94/32",
      "207.67.47.0/24",
    ] # This IP range includes AAMVA's failover, but is not exclusively controlled by AAMVA
  }

  egress {
    description = "Allow egress to Experian"
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = [
      "167.107.58.9/32",
    ]
  }

  ingress {
    description = "Allow ingress from VPC"
    from_port   = 3128
    to_port     = 3128
    protocol    = "tcp"
    cidr_blocks = compact([var.vpc_cidr_block, var.app_cidr_block])
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
