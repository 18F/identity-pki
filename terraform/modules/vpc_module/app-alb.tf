resource "aws_security_group" "app-alb" {
  count       = var.apps_enabled
  description = "App ALB group allowing Internet traffic"
  vpc_id      = aws_vpc.default.id

  # Allow outbound to the VPC so that we can get to the app hosts.
  # We use cidr_blocks rather than security_groups here so that we avoid a
  # bootstrapping cycle and will still remove unmanaged rules.
  # https://github.com/terraform-providers/terraform-provider-aws/issues/3095
  egress {
    description = "Permit HTTP to public subnets for app"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [for subnet in aws_subnet.app : subnet.cidr_block]
  }
  egress {
    description = "Permit HTTPS to public subnets for app"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for subnet in aws_subnet.app : subnet.cidr_block]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  name = "${var.env_name}-app-alb"

  tags = {
    Name = "${var.env_name}-app-alb"
  }
}