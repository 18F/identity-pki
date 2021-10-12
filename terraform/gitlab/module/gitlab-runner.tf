
module "gitlab_runner_user_data" {
  source = "../../modules/bootstrap/"

  role          = "gitlab_runner"
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

module "gitlab_runner_lifecycle_hooks" {
  source   = "github.com/18F/identity-terraform//asg_lifecycle_notifications?ref=b68c41068a53acbb981eeb37e1eb0a36a6487ac7"
  asg_name = aws_autoscaling_group.gitlab_runner.name
}

module "gitlab_runner_launch_template" {
  source = "github.com/18F/identity-terraform//launch_template?ref=b68c41068a53acbb981eeb37e1eb0a36a6487ac7"
  #source = "../../../identity-terraform/launch_template"
  role           = "gitlab_runner"
  env            = var.env_name
  root_domain    = var.root_domain
  ami_id_map     = var.ami_id_map
  default_ami_id = local.account_default_ami_id

  instance_type             = var.instance_type_gitlab_runner
  use_spot_instances        = var.use_spot_instances
  iam_instance_profile_name = aws_iam_instance_profile.gitlab_runner.name
  security_group_ids        = [aws_security_group.gitlab_runner.id, aws_security_group.base.id]

  user_data = module.gitlab_runner_user_data.rendered_cloudinit_config

  template_tags = {
    "main_git_ref" = module.gitlab_runner_user_data.main_git_ref
  }
}

resource "aws_autoscaling_group" "gitlab_runner" {
  name = "${var.env_name}-gitlab_runner"

  launch_template {
    id      = module.gitlab_runner_launch_template.template_id
    version = "$Latest"
  }

  min_size         = 1
  max_size         = 4 # TODO count subnets or Region's AZ width
  desired_capacity = var.asg_gitlab_runner_desired

  wait_for_capacity_timeout = 0 # 0 == ignore

  # https://github.com/18F/identity-devops-private/issues/259
  vpc_zone_identifier = [
    aws_subnet.gitlab1.id,
    aws_subnet.gitlab2.id,
  ]

  health_check_type         = "EC2"
  health_check_grace_period = 1
  termination_policies      = ["OldestInstance"]

  # tags on the instance will come from the launch template
  tag {
    key                 = "prefix"
    value               = "gitlab_runner"
    propagate_at_launch = false
  }
  tag {
    key                 = "domain"
    value               = "${var.env_name}.${var.root_domain}"
    propagate_at_launch = false
  }
  tag {
    key                 = "environment"
    value               = var.env_name
    propagate_at_launch = false
  }

  # We manually terminate instances in prod
  protect_from_scale_in = var.asg_prevent_auto_terminate == 1 ? true : false
}

resource "aws_iam_instance_profile" "gitlab_runner" {
  name = "${var.env_name}_gitlab_runner_instance_profile"
  role = aws_iam_role.gitlab_runner.name
}

resource "aws_iam_role" "gitlab_runner" {
  name               = "${var.env_name}_gitlab_runner_iam_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_from_vpc.json
}

# Role policy that associates it with the secrets_role_policy
resource "aws_iam_role_policy" "gitlab_runner-secrets" {
  name   = "${var.env_name}-gitlab_runner-secrets"
  role   = aws_iam_role.gitlab_runner.id
  policy = data.aws_iam_policy_document.secrets_role_policy.json
}

# Role policy that associates it with the common_secrets_role_policy
resource "aws_iam_role_policy" "gitlab_runner-common-secrets" {
  name   = "${var.env_name}-gitlab_runner-common-secrets"
  role   = aws_iam_role.gitlab_runner.id
  policy = data.aws_iam_policy_document.common_secrets_role_policy.json
}

# Role policy that associates it with the certificates_role_policy
resource "aws_iam_role_policy" "gitlab_runner-certificates" {
  name   = "${var.env_name}-gitlab_runner-certificates"
  role   = aws_iam_role.gitlab_runner.id
  policy = data.aws_iam_policy_document.certificates_role_policy.json
}

# Role policy that associates it with the describe_instances_role_policy
resource "aws_iam_role_policy" "gitlab_runner-describe_instances" {
  name   = "${var.env_name}-gitlab_runner-describe_instances"
  role   = aws_iam_role.gitlab_runner.id
  policy = data.aws_iam_policy_document.describe_instances_role_policy.json
}

resource "aws_iam_role_policy" "gitlab_runner-cloudwatch-logs" {
  name   = "${var.env_name}-gitlab_runner-cloudwatch-logs"
  role   = aws_iam_role.gitlab_runner.id
  policy = data.aws_iam_policy_document.cloudwatch-logs.json
}

resource "aws_iam_role_policy" "gitlab_runner-cloudwatch-agent" {
  name   = "${var.env_name}-gitlab_runner-cloudwatch-agent"
  role   = aws_iam_role.gitlab_runner.id
  policy = data.aws_iam_policy_document.cloudwatch-agent.json
}

# allow SSM service core functionality
resource "aws_iam_role_policy" "gitlab_runner-ssm-access" {
  name   = "${var.env_name}-gitlab_runner-ssm-access"
  role   = aws_iam_role.gitlab_runner.id
  policy = data.aws_iam_policy_document.ssm_access_role_policy.json
}

# allow all instances to send a dying SNS notice
resource "aws_iam_role_policy" "gitlab_runner-sns-publish-alerts" {
  name   = "${var.env_name}-gitlab_runner-sns-publish-alerts"
  role   = aws_iam_role.gitlab_runner.id
  policy = data.aws_iam_policy_document.sns-publish-alerts-policy.json
}
