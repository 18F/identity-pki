module "app_user_data" {
  count  = var.apps_enabled
  source = "../modules/bootstrap/"

  role          = "app"
  env           = var.env_name
  domain        = var.root_domain
  sns_topic_arn = var.slack_events_sns_hook_arn

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

module "app_lifecycle_hooks" {
  count    = var.apps_enabled
  source   = "github.com/18F/identity-terraform//asg_lifecycle_notifications?ref=e7ad5ef38f724b31911248a74173e9fee3bbf045"
  asg_name = aws_autoscaling_group.app[count.index].name
  enabled  = var.apps_enabled
}

module "app_launch_template" {
  count  = var.apps_enabled
  source = "github.com/18F/identity-terraform//launch_template?ref=e7ad5ef38f724b31911248a74173e9fee3bbf045"
  #source = "../../../identity-terraform/launch_template"

  role           = "app"
  env            = var.env_name
  root_domain    = var.root_domain
  ami_id_map     = var.ami_id_map
  default_ami_id = local.account_rails_ami_id

  instance_type             = var.instance_type_app
  use_spot_instances        = var.use_spot_instances
  iam_instance_profile_name = aws_iam_instance_profile.app[count.index].name
  security_group_ids        = [aws_security_group.app[count.index].id, aws_security_group.base.id]

  user_data = module.app_user_data[count.index].rendered_cloudinit_config

  template_tags = {
    main_git_ref = module.app_user_data[count.index].main_git_ref
  }
}

resource "aws_autoscaling_group" "app" {
  # Don't create an app ASG if we don't have an ALB.
  # We can't refer to aws_alb_target_group.app unless it exists.
  count = var.apps_enabled

  launch_template {
    id      = module.app_launch_template[count.index].template_id
    version = "$Latest"
  }

  name                      = "${var.env_name}-app"
  min_size                  = var.asg_app_min
  max_size                  = var.asg_app_max
  desired_capacity          = var.asg_app_desired
  wait_for_capacity_timeout = 0

  target_group_arns = [
    aws_alb_target_group.app[count.index].arn,
    aws_alb_target_group.app-ssl[count.index].arn,
  ]

  vpc_zone_identifier = [for subnet in aws_subnet.app : subnet.id]

  # possible choices: EC2, ELB
  health_check_type = "ELB"

  health_check_grace_period = 1

  termination_policies = ["OldestInstance"]

  # Because bootstrapping takes so long, we terminate manually in prod
  # More context on ASG deploys and safety:
  # https://github.com/18F/identity-devops-private/issues/337
  protect_from_scale_in = var.asg_prevent_auto_terminate == 1 ? true : false

  # tags on the instance will come from the launch template
  tag {
    key                 = "prefix"
    value               = "app"
    propagate_at_launch = false
  }
  tag {
    key                 = "domain"
    value               = "${var.env_name}.${var.root_domain}"
    propagate_at_launch = false
  }
  tag {
    key                 = "fisma"
    value               = var.fisma_tag
    propagate_at_launch = true
  }

  depends_on = [
    aws_autoscaling_group.outboundproxy,
    aws_cloudwatch_log_group.nginx_access_log
  ]
}

module "app_recycle" {
  count  = var.apps_enabled
  source = "github.com/18F/identity-terraform//asg_recycle?ref=e7ad5ef38f724b31911248a74173e9fee3bbf045"
  #source = "../../../identity-terraform/asg_recycle"

  asg_name       = aws_autoscaling_group.app[count.index].name
  normal_min     = var.asg_app_min
  normal_max     = var.asg_app_max
  normal_desired = var.asg_app_desired
  scale_schedule = var.autoscaling_schedule_name
  time_zone      = var.autoscaling_time_zone
}

resource "aws_iam_instance_profile" "app" {
  count = var.apps_enabled
  name  = "${var.env_name}_app_instance_profile"
  role  = aws_iam_role.app[count.index].name
}

resource "aws_iam_role" "app" {
  count              = var.apps_enabled
  name               = "${var.env_name}_app_iam_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_from_vpc.json
}

resource "aws_iam_role_policy" "app-secrets-manager" {
  count  = var.apps_enabled
  name   = "${var.env_name}-app-secrets-manager"
  role   = aws_iam_role.app[count.index].id
  policy = <<EOM
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:DescribeSecret",
                "secretsmanager:List*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "secretsmanager:Get*",
            "Resource": [
                "arn:aws:secretsmanager:*:*:secret:global/common/*",
                "arn:aws:secretsmanager:*:*:secret:global/app/*",
                "arn:aws:secretsmanager:*:*:secret:${var.env_name}/common/*",
                "arn:aws:secretsmanager:*:*:secret:${var.env_name}/app/*",
                "arn:aws:secretsmanager:*:*:secret:${var.env_name}/sp-oidc-sinatra/*"
            ]
        }
    ]
}
EOM

}

resource "aws_iam_role_policy" "app-s3-logos-access" {
  count  = var.apps_enabled
  name   = "${var.env_name}-app-s3-logos-access"
  role   = aws_iam_role.app[count.index].id
  policy = <<EOM
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:AbortMultipartUpload",
                "s3:GetObject",
                "s3:ListObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::login-gov-partner-logos-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}",
                "arn:aws:s3:::login-gov-partner-logos-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}/*"
            ]
        }
    ]
}
EOM
}

# Allow publishing traces to X-Ray
resource "aws_iam_role_policy" "app-xray-publish" {
  count  = var.apps_enabled
  name   = "${var.env_name}-app-xray-publish"
  role   = aws_iam_role.app[count.index].id
  policy = data.aws_iam_policy_document.xray-publish-policy.json
}

# These policies are all duplicated from base-permissions

resource "aws_iam_role_policy" "app-secrets" {
  count  = var.apps_enabled
  name   = "${var.env_name}-app-secrets"
  role   = aws_iam_role.app[count.index].id
  policy = data.aws_iam_policy_document.secrets_role_policy.json
}

# Role policy that associates it with the certificates_role_policy
resource "aws_iam_role_policy" "app-certificates" {
  count  = var.apps_enabled
  name   = "${var.env_name}-app-certificates"
  role   = aws_iam_role.app[count.index].id
  policy = data.aws_iam_policy_document.certificates_role_policy.json
}

# Role policy that associates it with the describe_instances_role_policy
resource "aws_iam_role_policy" "app-describe_instances" {
  count  = var.apps_enabled
  name   = "${var.env_name}-app-describe_instances"
  role   = aws_iam_role.app[count.index].id
  policy = data.aws_iam_policy_document.describe_instances_role_policy.json
}

resource "aws_iam_role_policy" "app-ses-email" {
  count  = var.apps_enabled
  name   = "${var.env_name}-app-ses-email"
  role   = aws_iam_role.app[count.index].id
  policy = data.aws_iam_policy_document.ses_email_role_policy.json
}

resource "aws_iam_role_policy" "app-cloudwatch-logs" {
  count  = var.apps_enabled
  name   = "${var.env_name}-app-cloudwatch-logs"
  role   = aws_iam_role.app[count.index].id
  policy = data.aws_iam_policy_document.cloudwatch-logs.json
}

resource "aws_iam_role_policy" "app-cloudwatch-agent" {
  count  = var.apps_enabled
  name   = "${var.env_name}-app-cloudwatch-agent"
  role   = aws_iam_role.app[count.index].id
  policy = data.aws_iam_policy_document.cloudwatch-agent.json
}

resource "aws_iam_role_policy" "app-ssm-access" {
  count  = var.apps_enabled
  name   = "${var.env_name}-app-ssm-access"
  role   = aws_iam_role.app[count.index].id
  policy = module.ssm.ssm_access_role_policy
}

resource "aws_iam_role_policy" "app-sns-publish-alerts" {
  count  = var.apps_enabled
  name   = "${var.env_name}-app-sns-publish-alerts"
  role   = aws_iam_role.app[count.index].id
  policy = data.aws_iam_policy_document.sns-publish-alerts-policy.json
}

resource "aws_iam_role_policy" "app-transfer-utility" {
  count  = var.apps_enabled
  name   = "${var.env_name}-app-transfer-utility"
  role   = aws_iam_role.app[count.index].id
  policy = data.aws_iam_policy_document.transfer_utility_policy.json
}

# </end> base-permissions policies
