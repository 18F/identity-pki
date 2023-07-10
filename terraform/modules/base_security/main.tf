# Base security group added to all instances, grants default permissions like
# ingress SSH and ICMP.
resource "aws_security_group" "base" {
  name        = "${var.env_name}-base"
  description = "Base security group for rules common to all instances"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.env_name}-base"
  }

  # allow TCP egress to outbound proxy
  egress {
    description     = "allow egress to outbound proxy"
    protocol        = "tcp"
    from_port       = var.proxy_port
    to_port         = var.proxy_port
    security_groups = [var.obproxy_security_group]
  }

  # allow ICMP to/from the whole VPC
  ingress {
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = [var.vpc_cidr_block]
  }
  egress {
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = [var.vpc_cidr_block]
  }

  # allow access to the VPC private S3 endpoint
  egress {
    description     = "allow egress to VPC S3 endpoint"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [var.s3_prefix_list_id]
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