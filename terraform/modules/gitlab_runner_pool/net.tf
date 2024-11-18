data "aws_ip_ranges" "ec2_argo" {
  regions  = ["us-west-2"]
  services = ["ec2"]
}

locals {
  security_group_max_rules = 120

  chunked_result = { for index, chunk in chunklist(
    data.aws_ip_ranges.ec2_argo.cidr_blocks, local.security_group_max_rules
  ) : index => chunk }
}

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

moved {
  from = aws_security_group.gitlab_runner_2
  to   = aws_security_group.gitlab_runner_ec2_access[0]
}

# first security group ran out of rules so expand to another SG
resource "aws_security_group" "gitlab_runner_ec2_access" {
  for_each    = local.chunked_result
  description = "gitlab runner security group argo access"

  # argo load balancers are managed by aws and the ip addresses could be
  # anything, this is the least obtrusive way we could find to do this without
  # setting up privatelink or vpc peering (which may not work or could change if
  # load balancer configs change out from under us anyway)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = each.value
    description = "Allow connection to ec2 (argocd)"
  }

  name_prefix = "${var.name}-gitlabrunner${each.key + 2}-${var.env_name}"

  tags = {
    Name = "${var.name}-gitlab_runner_security_group${each.key + 2}-${var.env_name}"
    role = "gitlab"
  }

  vpc_id = var.aws_vpc
}
