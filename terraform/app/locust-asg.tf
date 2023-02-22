module "locust_user_data" {
  count  = var.enable_loadtesting ? 1 : 0
  source = "../modules/bootstrap/"

  role                   = "locust"
  env                    = var.env_name
  domain                 = var.root_domain
  s3_secrets_bucket_name = data.aws_s3_bucket.secrets.bucket
  sns_topic_arn          = var.slack_events_sns_hook_arn

  chef_download_url    = var.chef_download_url
  chef_download_sha256 = var.chef_download_sha256

  # identity-devops-private variables
  private_s3_ssh_key_url = local.bootstrap_private_s3_ssh_key_url
  private_git_clone_url  = var.bootstrap_private_git_clone_url
  private_git_ref        = local.bootstrap_private_git_ref

  # identity-devops variables
  main_s3_ssh_key_url  = local.bootstrap_main_s3_ssh_key_url
  main_git_clone_url   = var.bootstrap_main_git_clone_url
  main_git_ref_map     = var.bootstrap_main_git_ref_map
  main_git_ref_default = local.bootstrap_main_git_ref_default

  # proxy variables
  proxy_server        = var.proxy_server
  proxy_port          = var.proxy_port
  no_proxy_hosts      = var.no_proxy_hosts
  proxy_enabled_roles = var.proxy_enabled_roles
}

resource "aws_security_group" "locust" {
  count       = var.enable_loadtesting ? 1 : 0
  name        = "${var.name}-locust-${var.env_name}"
  vpc_id      = aws_vpc.default.id
  description = "Allows locust hosts to run distributed loadtests against the environment"

  # TODO: limit this to what is actually needed
  # allow outbound to the VPC so that we can get to db/redis/logstash/etc.
  egress {
    description = ""
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block, aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block]
  }

  # need 80/443 to get packages/gems/etc
  egress {
    description = ""
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # need 80/443 to get packages/gems/etc
  egress {
    description = ""
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # need 8834 to comm with Nessus Server
  egress {
    description = ""
    from_port   = 8834
    to_port     = 8834
    protocol    = "tcp"
    cidr_blocks = [var.nessusserver_ip]
  }

  # github
  egress {
    description = ""
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"

    # github
    cidr_blocks = local.github_ipv4
  }

  #s3 gateway
  egress {
    description     = ""
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.private-s3.prefix_list_id]
  }

  # locust distributed
  egress {
    description = ""
    from_port   = 5557
    to_port     = 5557
    protocol    = "tcp"
    self        = true
  }

  # locust distributed
  ingress {
    description = ""
    from_port   = 5557
    to_port     = 5557
    protocol    = "tcp"
    self        = true
  }

  # need 8834 to comm with Nessus Server
  ingress {
    description = ""
    from_port   = 8834
    to_port     = 8834
    protocol    = "tcp"
    cidr_blocks = [var.nessusserver_ip]
  }

  tags = {
    Name = "${var.name}-locust_security_group-${var.env_name}"
    role = "locust"
  }
}
