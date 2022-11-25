resource "aws_iam_instance_profile" "idp" {
  name = "${var.env_name}_idp_instance_profile"
  role = aws_iam_role.idp.name
}

resource "aws_iam_role" "idp" {
  name               = "${var.env_name}_idp_iam_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_from_vpc.json
}

resource "aws_iam_role_policy" "idp-download-artifacts" {
  name   = "${var.env_name}-idp-artifacts"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.download_artifacts_role_policy.json
}

resource "aws_iam_role_policy" "idp-secrets" {
  name   = "${var.env_name}-idp-secrets"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.secrets_role_policy.json
}

resource "aws_iam_role_policy" "idp-transfer-utility" {
  name   = "${var.env_name}-idp-transfer-utility"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.transfer_utility_policy.json
}

resource "aws_iam_role_policy" "idp-secrets-manager" {
  name   = "${var.env_name}-idp-secrets-manager"
  role   = aws_iam_role.idp.id
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
                "arn:aws:secretsmanager:*:*:secret:global/idp/*",
                "arn:aws:secretsmanager:*:*:secret:${var.env_name}/common/*",
                "arn:aws:secretsmanager:*:*:secret:${var.env_name}/idp/*"
            ]
        }
    ]
}
EOM

}

# Allow listing CloudHSM clusters
resource "aws_iam_role_policy" "idp-cloudhsm-client" {
  name   = "${var.env_name}-idp-cloudhsm-client"
  role   = aws_iam_role.idp.id
  policy = <<EOM
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudhsm:DescribeClusters",
                "cloudhsm:ListTags",
                "cloudhsm:ListTagsForResource"
            ],
            "Resource": "*"
        }
    ]
}
EOM

}

resource "aws_iam_role_policy" "idp-certificates" {
  name   = "${var.env_name}-idp-certificates"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.certificates_role_policy.json
}

resource "aws_iam_role_policy" "idp-describe_instances" {
  name   = "${var.env_name}-idp-describe_instances"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.describe_instances_role_policy.json
}

resource "aws_iam_role_policy" "idp-application-secrets" {
  name   = "${var.env_name}-idp-application-secrets"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.application_secrets_role_policy.json
}

resource "aws_iam_role_policy" "idp-ses-email" {
  name   = "${var.env_name}-idp-ses-email"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.ses_email_role_policy.json
}

resource "aws_iam_role_policy" "idp-cloudwatch-logs" {
  name   = "${var.env_name}-idp-cloudwatch-logs"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.cloudwatch-logs.json
}

resource "aws_iam_role_policy" "idp-cloudwatch-agent" {
  name   = "${var.env_name}-idp-cloudwatch-agent"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.cloudwatch-agent.json
}

resource "aws_iam_role_policy" "idp-upload-s3-reports" {
  name   = "${var.env_name}-idp-s3-reports"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.put_reports_to_s3.json
}

resource "aws_iam_role_policy" "idp-ssm-access" {
  name   = "${var.env_name}-idp-ssm-access"
  role   = aws_iam_role.idp.id
  policy = module.ssm.ssm_access_role_policy
}

resource "aws_iam_role_policy" "idp-sns-publish-alerts" {
  name   = "${var.env_name}-idp-sns-publish-alerts"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.sns-publish-alerts-policy.json
}

resource "aws_iam_role_policy" "idp-ec2-tags" {
  name   = "${var.env_name}-idp-ec2-tags"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.ec2-tags.json
}

# This policy allows writing to the S3 reports bucket
data "aws_iam_policy_document" "put_reports_to_s3" {
  statement {
    sid    = "PutObjectsToReportsS3Bucket"
    effect = "Allow"
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "arn:aws:s3:::login-gov.reports.${data.aws_caller_identity.current.account_id}-${var.region}/${var.env_name}/*",
    ]
  }

  # allow listing objects so we can see what we've uploaded
  statement {
    sid    = "ListBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::login-gov.reports.${data.aws_caller_identity.current.account_id}-${var.region}",
    ]
  }
}

# Allow assuming cross-account role for Pinpoint APIs. This is in a separate
# account for accounting purposes since it's on a separate contract.
resource "aws_iam_role_policy" "idp-pinpoint-assumerole" {
  name   = "${var.env_name}-idp-pinpoint-assumerole"
  role   = aws_iam_role.idp.id
  policy = <<EOM
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": [
        "arn:aws:iam::${var.identity_sms_aws_account_id}:role/${var.identity_sms_iam_role_name_idp}"
      ]
    }
  ]
}
EOM

}

# Allow publishing traces to X-Ray
resource "aws_iam_role_policy" "idp-xray-publish" {
  name   = "${var.env_name}-idp-xray-publish"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.xray-publish-policy.json
}

module "idp_user_data" {
  source = "../modules/bootstrap/"

  role          = "idp"
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

module "idp_launch_template" {
  source = "github.com/18F/identity-terraform//launch_template?ref=5d344d205dd09eb85d5de1ff1081c4a598afe433"
  #source = "../../../identity-terraform/launch_template"

  role           = "idp"
  env            = var.env_name
  root_domain    = var.root_domain
  ami_id_map     = var.ami_id_map
  default_ami_id = local.account_rails_ami_id

  instance_type             = var.instance_type_idp
  iam_instance_profile_name = aws_iam_instance_profile.idp.name
  security_group_ids        = [aws_security_group.idp.id, aws_security_group.base.id]
  user_data                 = module.idp_user_data.rendered_cloudinit_config

  use_spot_instances = var.use_spot_instances == 1 ? (
    length(var.idp_mixed_instance_config) == 0 ? 1 : 0
  ) : 0

  template_tags = {
    main_git_ref = module.idp_user_data.main_git_ref
  }
}

resource "aws_autoscaling_group" "idp" {
  name = "${var.env_name}-idp"

  # use launch_template if var.idp_mixed_instance_config is not specified;
  # otherwise will throw InvalidQueryParameter error if var.use_spot_instances == 1
  dynamic "launch_template" {
    for_each = length(var.idp_mixed_instance_config) == 0 ? [1] : []

    content {
      id      = module.idp_launch_template.template_id
      version = "$Latest"
    }
  }

  dynamic "mixed_instances_policy" {
    for_each = length(var.idp_mixed_instance_config) == 0 ? [] : [1]

    content {
      instances_distribution {
        on_demand_base_capacity = (
          var.use_spot_instances == 1 ? 0 : var.asg_idp_max
        )
        on_demand_percentage_above_base_capacity = (
          var.use_spot_instances != 1 ? 100 : 0
        )
        spot_allocation_strategy = "capacity-optimized"
      }

      launch_template {
        launch_template_specification {
          launch_template_id = module.idp_launch_template.template_id
          version            = "$Latest"
        }

        # at least one override, containing the instance type within
        # the launch template, must be present
        override {
          instance_type     = var.instance_type_idp
          weighted_capacity = var.idp_default_weight
        }

        dynamic "override" {
          for_each = var.idp_mixed_instance_config

          content {
            instance_type     = override.value.instance_type
            weighted_capacity = override.value.weighted_capacity
          }
        }
      }
    }
  }

  min_size         = var.asg_idp_min
  max_size         = var.asg_idp_max
  desired_capacity = var.asg_idp_desired

  wait_for_capacity_timeout = 0

  target_group_arns = [
    aws_alb_target_group.idp.arn,
    aws_alb_target_group.idp-ssl.arn,
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

  enabled_metrics = var.asg_enabled_metrics

  # tags on the instance will come from the launch template
  tag {
    key                 = "prefix"
    value               = "idp"
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
    aws_autoscaling_group.migration,
  ]
}

module "idp_lifecycle_hooks" {
  source   = "github.com/18F/identity-terraform//asg_lifecycle_notifications?ref=5d344d205dd09eb85d5de1ff1081c4a598afe433"
  asg_name = aws_autoscaling_group.idp.name
}

module "idp_recycle" {
  source = "github.com/18F/identity-terraform//asg_recycle?ref=72f86a962807f84f5f5980c1bcffb9439d25d9df"
  #source = "../../../identity-terraform/asg_recycle"

  asg_name       = aws_autoscaling_group.idp.name
  normal_min     = var.asg_idp_min
  normal_max     = var.asg_idp_max
  normal_desired = var.asg_idp_desired
  scale_schedule = var.autoscaling_schedule_name
  time_zone      = var.autoscaling_time_zone
}

resource "aws_autoscaling_policy" "idp-cpu" {
  count = var.idp_cpu_autoscaling_enabled

  autoscaling_group_name = aws_autoscaling_group.idp.name
  name                   = "cpu-scaling"

  # currently it takes about 15 minutes for instances to bootstrap
  estimated_instance_warmup = 900

  policy_type = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = var.idp_cpu_autoscaling_target

    disable_scale_in = var.idp_cpu_autoscaling_disable_scale_in == 1 ? true : false
  }
}
