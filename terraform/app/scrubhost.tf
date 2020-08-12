# If we used named policies I could have just referenced them, but Inline it is!
resource "aws_iam_role" "scrub-permissions" {
  name               = "${var.env_name}-scrub-permissions"
  assume_role_policy = data.aws_iam_policy_document.assume_role_from_vpc.json
}

# Role policy that associates it with the secrets_role_policy
resource "aws_iam_role_policy" "scrub-permissions-secrets" {
  name   = "${var.env_name}-scrub-permissions-secrets"
  role   = aws_iam_role.scrub-permissions.id
  policy = data.aws_iam_policy_document.secrets_role_policy.json
}

# Role policy that associates it with the certificates_role_policy
resource "aws_iam_role_policy" "scrub-permissions-certificates" {
  name   = "${var.env_name}-scrub-permissions-certificates"
  role   = aws_iam_role.scrub-permissions.id
  policy = data.aws_iam_policy_document.certificates_role_policy.json
}

# Role policy that associates it with the describe_instances_role_policy
resource "aws_iam_role_policy" "scrub-permissions-describe_instances" {
  name   = "${var.env_name}-scrub-permissions-describe_instances"
  role   = aws_iam_role.scrub-permissions.id
  policy = data.aws_iam_policy_document.describe_instances_role_policy.json
}

resource "aws_iam_role_policy" "scrub-permissions-cloudwatch-logs" {
  name   = "${var.env_name}-scrub-permissions-cloudwatch-logs"
  role   = aws_iam_role.scrub-permissions.id
  policy = data.aws_iam_policy_document.cloudwatch-logs.json
}

resource "aws_iam_role_policy" "scrub-permissions-cloudwatch-agent" {
  name   = "${var.env_name}-scrub-permissions-cloudwatch-agent"
  role   = aws_iam_role.scrub-permissions.id
  policy = data.aws_iam_policy_document.cloudwatch-agent.json
}

# allow all the base instances to grab an EIP
resource "aws_iam_role_policy" "scrub-permissions-auto-eip" {
  name   = "${var.env_name}-scrub-permissions-auto-eip"
  role   = aws_iam_role.scrub-permissions.id
  policy = data.aws_iam_policy_document.auto_eip_policy.json
}

# allow SSM service core functionality
resource "aws_iam_role_policy" "scrub-permissions-ssm-access" {
  name   = "${var.env_name}-scrub-permissions-ssm-access"
  role   = aws_iam_role.scrub-permissions.id
  policy = data.aws_iam_policy_document.ssm_access_role_policy.json
}

resource "aws_iam_role_policy" "scrub-sns-publish-alerts" {
  name   = "${var.env_name}-scrub-sns-publish-alerts"
  role   = aws_iam_role.scrub-permissions.id
  policy = data.aws_iam_policy_document.sns-publish-alerts-policy.json
}

# Read only access to log-scrub bucket - destination for CloudWatch raw
# exports
resource "aws_iam_role_policy" "scrub-permissions-log-scrub-bucket" {
  name   = "${var.env_name}-scrub-permissions-log-scrub-bucket"
  role   = aws_iam_role.scrub-permissions.id
  policy = data.aws_iam_policy_document.log_scrub_bucket_read_policy.json
}

# Log bucket access for storing scrubbed logs
resource "aws_iam_role_policy" "scrub-permissions-logbucket-access" {
  name   = "${var.env_name}-scrub-permissions-logbucket-access"
  role   = aws_iam_role.scrub-permissions.id
  policy = data.aws_iam_policy_document.logbucketpolicy.json
}

# Additional policy needed for scrubbing logs CloudWatch
resource "aws_iam_role_policy" "scrub-permissions-cloudwatch-full" {
  name   = "${var.env_name}-scrub-permissions-cloudwatch-full"
  role   = aws_iam_role.scrub-permissions.id
  policy = data.aws_iam_policy_document.cloudwatch_scrub.json
}

# Danger: This set of permissions allows deleting log streams
data "aws_iam_policy_document" "cloudwatch_scrub" {
  statement {
    sid    = "AllowCloudWatchLogsFull"
    effect = "Allow"
    actions = [
      "logs:*"
    ]
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

# IAM instance profile with scrubbing bubbles
resource "aws_iam_instance_profile" "scrub-permissions" {
  name = "${var.env_name}-scrub-permissions"
  role = aws_iam_role.scrub-permissions.name
}

module "scrubhost_user_data" {
  source = "../modules/bootstrap/"

  role          = "scrubhost"
  env           = var.env_name
  domain        = var.root_domain
  sns_topic_arn = var.slack_events_sns_hook_arn

  chef_download_url    = var.chef_download_url
  chef_download_sha256 = var.chef_download_sha256

  # identity-devops-private variables
  private_s3_ssh_key_url = local.bootstrap_private_s3_ssh_key_url
  private_git_clone_url  = var.bootstrap_private_git_clone_url
  private_git_ref        = var.bootstrap_private_git_ref

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

resource "aws_security_group" "scrubhost" {
  description = "Security group for scrubhosts"

  # In-VPC outbound
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # need to get packages and stuff (conditionally)
  # outbound_subnets can be set to "0.0.0.0/0" to allow access to the internet
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.outbound_subnets
  }

  # need to get packages and stuff (conditionally)
  # outbound_subnets can be set to "0.0.0.0/0" to allow access to the internet
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.outbound_subnets
  }

  # github
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["192.30.252.0/22"]
  }

  name = "${var.env_name}-scrubhost"

  tags = {
    Name = "${var.name}-scrubhost_security_group-${var.env_name}"
    role = "app"
  }

  vpc_id = aws_vpc.default.id
}

module "scrubhost_launch_template" {
  source = "github.com/18F/identity-terraform//launch_template?ref=19a1a7d7a5c3e2177f62d96a553fed53ac2c251c"

  role           = "scrubhost"
  env            = var.env_name
  root_domain    = var.root_domain
  ami_id_map     = var.ami_id_map
  default_ami_id = local.account_default_ami_id

  instance_type             = var.instance_type_scrubhost
  iam_instance_profile_name = aws_iam_instance_profile.scrub-permissions.name
  security_group_ids        = [aws_security_group.base.id, aws_security_group.scrubhost.id]

  user_data = module.scrubhost_user_data.rendered_cloudinit_config

  template_tags = {
    main_git_ref = module.scrubhost_user_data.main_git_ref
  }
}

resource "aws_autoscaling_group" "scrubhost" {
  name = "${var.env_name}-scrubhost"

  launch_template {
    id      = module.scrubhost_launch_template.template_id
    version = "$Latest"
  }

  min_size         = 0
  max_size         = 4 # TODO count subnets or Region's AZ width
  desired_capacity = var.asg_scrubhost_desired

  wait_for_capacity_timeout = 0 # 0 == ignore

  # No direct access should be required
  vpc_zone_identifier = [
    aws_subnet.publicsubnet1.id,
    aws_subnet.publicsubnet2.id,
    aws_subnet.publicsubnet3.id
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 1
  termination_policies      = ["OldestInstance"]

  # tags on the instance will come from the launch template
  tag {
    key                 = "prefix"
    value               = "scrubhost"
    propagate_at_launch = false
  }
  tag {
    key                 = "domain"
    value               = "${var.env_name}.${var.root_domain}"
    propagate_at_launch = false
  }

  # We manually terminate instances in prod
  protect_from_scale_in = var.asg_prevent_auto_terminate == 1 ? true : false
}
