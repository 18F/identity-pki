
module "gitlab_user_data" {
  source = "../../modules/bootstrap/"

  role          = "gitlab"
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

module "gitlab_lifecycle_hooks" {
  source   = "github.com/18F/identity-terraform//asg_lifecycle_notifications?ref=7e11ebe24e3a9cbc34d1413cf4d20b3d71390d5b"
  asg_name = aws_autoscaling_group.gitlab.name
}

module "gitlab_launch_template" {
  source = "github.com/18F/identity-terraform//launch_template?ref=7e11ebe24e3a9cbc34d1413cf4d20b3d71390d5b"
  #source = "../../../identity-terraform/launch_template"
  role           = "gitlab"
  env            = var.env_name
  root_domain    = var.root_domain
  ami_id_map     = var.ami_id_map
  default_ami_id = local.account_default_ami_id

  instance_type             = var.instance_type_gitlab
  use_spot_instances        = var.use_spot_instances
  iam_instance_profile_name = aws_iam_instance_profile.gitlab.name
  security_group_ids        = [aws_security_group.gitlab.id, aws_security_group.base.id]

  user_data = module.gitlab_user_data.rendered_cloudinit_config

  template_tags = {
    main_git_ref = module.gitlab_user_data.main_git_ref
  }
}

resource "aws_autoscaling_group" "gitlab" {
  name = "${var.env_name}-gitlab"

  launch_template {
    id      = module.gitlab_launch_template.template_id
    version = "$Latest"
  }

  min_size         = 1
  max_size         = 1 # TODO count subnets or Region's AZ width
  desired_capacity = var.asg_gitlab_desired

  wait_for_capacity_timeout = 0 # 0 == ignore

  # https://github.com/18F/identity-devops-private/issues/259
  vpc_zone_identifier = [
    aws_subnet.gitlab1.id,
  ]

  health_check_type         = "EC2"
  health_check_grace_period = 1
  termination_policies      = ["OldestInstance"]

  # tags on the instance will come from the launch template
  tag {
    key                 = "prefix"
    value               = "gitlab"
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

resource "aws_iam_instance_profile" "gitlab" {
  name = "${var.env_name}_gitlab_instance_profile"
  role = aws_iam_role.gitlab.name
}

resource "aws_autoscaling_attachment" "gitlab" {
  autoscaling_group_name = aws_autoscaling_group.gitlab.id
  elb                    = aws_elb.gitlab.id
}

resource "aws_iam_role" "gitlab" {
  name               = "${var.env_name}_gitlab_iam_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_from_vpc.json
}

# Role policy that associates it with the secrets_role_policy
resource "aws_iam_role_policy" "gitlab-secrets" {
  name   = "${var.env_name}-gitlab-secrets"
  role   = aws_iam_role.gitlab.id
  policy = data.aws_iam_policy_document.secrets_role_policy.json
}

# Role policy that associates it with the certificates_role_policy
resource "aws_iam_role_policy" "gitlab-certificates" {
  name   = "${var.env_name}-gitlab-certificates"
  role   = aws_iam_role.gitlab.id
  policy = data.aws_iam_policy_document.certificates_role_policy.json
}

# Role policy that associates it with the describe_instances_role_policy
resource "aws_iam_role_policy" "gitlab-describe_instances" {
  name   = "${var.env_name}-gitlab-describe_instances"
  role   = aws_iam_role.gitlab.id
  policy = data.aws_iam_policy_document.describe_instances_role_policy.json
}

resource "aws_iam_role_policy" "gitlab-cloudwatch-logs" {
  name   = "${var.env_name}-gitlab-cloudwatch-logs"
  role   = aws_iam_role.gitlab.id
  policy = data.aws_iam_policy_document.cloudwatch-logs.json
}

resource "aws_iam_role_policy" "gitlab-cloudwatch-agent" {
  name   = "${var.env_name}-gitlab-cloudwatch-agent"
  role   = aws_iam_role.gitlab.id
  policy = data.aws_iam_policy_document.cloudwatch-agent.json
}

# allow all the base instances to grab an EIP
resource "aws_iam_role_policy" "gitlab-auto-eip" {
  name   = "${var.env_name}-gitlab-auto-eip"
  role   = aws_iam_role.gitlab.id
  policy = data.aws_iam_policy_document.auto_eip_policy.json
}

# allow SSM service core functionality
resource "aws_iam_role_policy" "gitlab-ssm-access" {
  name   = "${var.env_name}-gitlab-ssm-access"
  role   = aws_iam_role.gitlab.id
  policy = data.aws_iam_policy_document.ssm_access_role_policy.json
}

# allow all instances to send a dying SNS notice
resource "aws_iam_role_policy" "gitlab-sns-publish-alerts" {
  name   = "${var.env_name}-gitlab-sns-publish-alerts"
  role   = aws_iam_role.gitlab.id
  policy = data.aws_iam_policy_document.sns-publish-alerts-policy.json
}

resource "aws_iam_role_policy" "gitlab-ebsvolume" {
  name   = "${var.env_name}-gitlab-ebsvolume"
  role   = aws_iam_role.gitlab.id
  policy = <<EOM
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AttachVolume",
                "ec2:DetachVolume"
            ],
            "Resource": "arn:aws:ec2:*:*:instance/*",
            "Condition": {
                "StringEquals": {"aws:ResourceTag/domain": "${var.env_name}.${var.root_domain}"}
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AttachVolume",
                "ec2:DetachVolume"
            ],
            "Resource": "arn:aws:ec2:*:*:volume/*",
            "Condition": {
                "StringEquals": {"aws:ResourceTag/Name": "${var.name}-gitaly-${var.env_name}"}
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AttachVolume",
                "ec2:DetachVolume"
            ],
            "Resource": "arn:aws:ec2:*:*:volume/*",
            "Condition": {
                "StringEquals": {"aws:ResourceTag/Name": "${var.name}-gitlab-${var.env_name}"}
            }
        }
    ]
}
EOM
}

resource "aws_ebs_volume" "gitlab" {
  # XXX gitlab only can live in one AZ because of the EBS volume.
  availability_zone = var.gitlab_az
  size              = 20
  encrypted         = true

  tags = {
    Name = "${var.name}-gitlab-${var.env_name}"
  }
}

output "gitlab_volume_id" {
  value = aws_ebs_volume.gitlab.id
}

resource "aws_iam_role_policy" "gitlab-s3buckets" {
  name   = "${var.env_name}-gitlab-s3buckets"
  role   = aws_iam_role.gitlab.id
  policy = <<EOM
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": ["s3:ListBucket"],
        "Resource": [
          "arn:aws:s3:::gitlab-${var.env_name}-artifacts",
          "arn:aws:s3:::gitlab-${var.env_name}-external-diffs",
          "arn:aws:s3:::gitlab-${var.env_name}-lfs-objects",
          "arn:aws:s3:::gitlab-${var.env_name}-uploads",
          "arn:aws:s3:::gitlab-${var.env_name}-packages",
          "arn:aws:s3:::gitlab-${var.env_name}-dependency-proxy",
          "arn:aws:s3:::gitlab-${var.env_name}-terraform-state",
          "arn:aws:s3:::gitlab-${var.env_name}-pages"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ],
        "Resource": [
          "arn:aws:s3:::gitlab-${var.env_name}-artifacts/*",
          "arn:aws:s3:::gitlab-${var.env_name}-external-diffs/*",
          "arn:aws:s3:::gitlab-${var.env_name}-lfs-objects/*",
          "arn:aws:s3:::gitlab-${var.env_name}-uploads/*",
          "arn:aws:s3:::gitlab-${var.env_name}-packages/*",
          "arn:aws:s3:::gitlab-${var.env_name}-dependency-proxy/*",
          "arn:aws:s3:::gitlab-${var.env_name}-terraform-state/*",
          "arn:aws:s3:::gitlab-${var.env_name}-pages/*"
        ]
      }
    ]
}
EOM
}

locals {
  gitlab_buckets = [
    "gitlab-${var.env_name}-artifacts",
    "gitlab-${var.env_name}-external-diffs",
    "gitlab-${var.env_name}-lfs-objects",
    "gitlab-${var.env_name}-uploads",
    "gitlab-${var.env_name}-packages",
    "gitlab-${var.env_name}-dependency-proxy",
    "gitlab-${var.env_name}-terraform-state",
    "gitlab-${var.env_name}-pages"
  ]
}

resource "aws_s3_bucket" "gitlab_buckets" {
  for_each = toset(local.gitlab_buckets)

  bucket = each.key
  acl    = "private"

  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "AES256"
      }
    }
  }
}
