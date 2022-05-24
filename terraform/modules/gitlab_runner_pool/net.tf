resource "aws_security_group" "gitlab_runner" {
  description = "gitlab runner security group"

  # TODO: Can we use HTTPS for provisioning instead?
  # github
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = sort(var.github_ipv4_cidr_blocks)
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = sort(var.github_ipv4_cidr_blocks)
  }

  # can talk to the proxy
  egress {
    from_port   = 3128
    to_port     = 3128
    protocol    = "tcp"
    cidr_blocks = module.outbound_proxy.proxy_lb_cidr_blocks
  }

  # need 8834 to comm with Nessus Server
  egress {
    from_port   = 8834
    to_port     = 8834
    protocol    = "tcp"
    cidr_blocks = [var.nessusserver_ip]
  }

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.gitlab_lb_interface_cidr_blocks
    description = "Allow connection from NLB"
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.gitlab_lb_interface_cidr_blocks
    description = "Allow connection from NLB"
  }

  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = var.endpoint_security_groups
    description     = "Allow connection to vpc endpoints"
  }

  name_prefix = "${var.name}-gitlabrunner-${var.env_name}"

  tags = {
    Name = "${var.name}-gitlab_runner_security_group-${var.env_name}"
    role = "gitlab"
  }

  vpc_id = var.aws_vpc
}
