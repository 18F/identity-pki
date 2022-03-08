resource "aws_security_group" "gitlab_runner" {
  description = "gitlab runner security group"

  # TODO: Can we use HTTPS for provisioning instead?
  # github
  egress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    # github
    cidr_blocks = sort(
      concat(
        var.github_ipv4_cidr_blocks,
        tolist(
          [
            var.gitlab1_subnet_cidr_block,
            var.gitlab2_subnet_cidr_block
          ]
        )
      )
    )
  }

  egress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = sort(
      tolist(
        [
          var.private1_subnet_cidr_block,
          var.private2_subnet_cidr_block,
          var.private3_subnet_cidr_block,
          var.gitlab1_subnet_cidr_block,
          var.gitlab2_subnet_cidr_block
        ]
      )
    )
  }

  # can talk to the proxy
  egress {
    from_port   = 3128
    to_port     = 3128
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # need 8834 to comm with Nessus Server
  egress {
    from_port   = 8834
    to_port     = 8834
    protocol    = "tcp"
    cidr_blocks = [var.nessusserver_ip]
  }

  name_prefix = "${var.name}-gitlabrunner-${var.env_name}"

  tags = {
    Name = "${var.name}-gitlab_runner_security_group-${var.env_name}"
    role = "gitlab"
  }

  vpc_id = var.aws_vpc
}
