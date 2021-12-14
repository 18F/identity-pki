module "pivcac_user_data" {
  source = "../modules/bootstrap/"

  role          = "pivcac"
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

module "pivcac_launch_template" {
  source = "github.com/18F/identity-terraform//launch_template?ref=7e11ebe24e3a9cbc34d1413cf4d20b3d71390d5b"
  #source = "../../../identity-terraform/launch_template"
  role           = "pivcac"
  env            = var.env_name
  root_domain    = var.root_domain
  ami_id_map     = var.ami_id_map
  default_ami_id = local.account_rails_ami_id

  instance_type             = var.instance_type_pivcac
  use_spot_instances        = var.use_spot_instances
  iam_instance_profile_name = aws_iam_instance_profile.pivcac.name
  security_group_ids        = [aws_security_group.pivcac.id, aws_security_group.base.id]

  user_data = module.pivcac_user_data.rendered_cloudinit_config

  template_tags = {
    main_git_ref = module.pivcac_user_data.main_git_ref
  }
}

module "pivcac_lifecycle_hooks" {
  source   = "github.com/18F/identity-terraform//asg_lifecycle_notifications?ref=7e11ebe24e3a9cbc34d1413cf4d20b3d71390d5b"
  asg_name = aws_autoscaling_group.pivcac.name
}

module "pivcac_recycle" {
  source = "github.com/18F/identity-terraform//asg_recycle?ref=7e11ebe24e3a9cbc34d1413cf4d20b3d71390d5b"

  # switch to count when that's a thing that we can do
  # https://github.com/hashicorp/terraform/issues/953
  enabled = var.asg_auto_recycle_enabled

  use_daily_business_hours_schedule = var.asg_recycle_business_hours

  asg_name                = aws_autoscaling_group.pivcac.name
  normal_desired_capacity = aws_autoscaling_group.pivcac.desired_capacity
}

resource "aws_iam_instance_profile" "pivcac" {
  name = "${var.env_name}_pivcac_instance_profile"
  role = aws_iam_role.pivcac.name
}

resource "aws_iam_role" "pivcac" {
  name               = "${var.env_name}_pivcac_iam_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_from_vpc.json
}

resource "aws_iam_role_policy" "pivcac-secrets" {
  name   = "${var.env_name}-pivcac-secrets"
  role   = aws_iam_role.pivcac.id
  policy = data.aws_iam_policy_document.secrets_role_policy.json
}

resource "aws_iam_role_policy" "pivcac-certificates" {
  name   = "${var.env_name}-pivcac-certificates"
  role   = aws_iam_role.pivcac.id
  policy = data.aws_iam_policy_document.certificates_role_policy.json
}

resource "aws_iam_role_policy" "pivcac-describe_instances" {
  name   = "${var.env_name}-pivcac-describe_instances"
  role   = aws_iam_role.pivcac.id
  policy = data.aws_iam_policy_document.describe_instances_role_policy.json
}

resource "aws_iam_role_policy" "pivcac-cloudwatch-logs" {
  name   = "${var.env_name}-pivcac-cloudwatch-logs"
  role   = aws_iam_role.pivcac.id
  policy = data.aws_iam_policy_document.cloudwatch-logs.json
}

resource "aws_iam_role_policy" "pivcac-cloudwatch-agent" {
  name   = "${var.env_name}-pivcac-cloudwatch-agent"
  role   = aws_iam_role.pivcac.id
  policy = data.aws_iam_policy_document.cloudwatch-agent.json
}

resource "aws_iam_role_policy" "pivcac-ssm-access" {
  name   = "${var.env_name}-pivcac-ssm-access"
  role   = aws_iam_role.pivcac.id
  policy = data.aws_iam_policy_document.ssm_access_role_policy.json
}

resource "aws_iam_role_policy" "pivcac-sns-publish-alerts" {
  name   = "${var.env_name}-pivcac-sns-publish-alerts"
  role   = aws_iam_role.pivcac.id
  policy = data.aws_iam_policy_document.sns-publish-alerts-policy.json
}

# Allow publishing traces to X-Ray
resource "aws_iam_role_policy" "pivcac-xray-publish" {
  name   = "${var.env_name}-pivcac-xray-publish"
  role   = aws_iam_role.pivcac.id
  policy = data.aws_iam_policy_document.xray-publish-policy.json
}

resource "aws_autoscaling_group" "pivcac" {
  name = "${var.env_name}-pivcac"

  launch_template {
    id      = module.pivcac_launch_template.template_id
    version = "$Latest"
  }

  min_size         = var.asg_pivcac_min == 0 ? 0 : var.asg_pivcac_min
  max_size         = var.asg_pivcac_max == 0 ? var.asg_pivcac_desired * 2 : var.asg_pivcac_max
  desired_capacity = var.asg_pivcac_desired

  wait_for_capacity_timeout = 0

  # Use the same subnet as the IDP.
  vpc_zone_identifier = [
    aws_subnet.idp1.id,
    aws_subnet.idp2.id,
  ]

  load_balancers = [aws_elb.pivcac.id]

  health_check_type         = "ELB"
  health_check_grace_period = 1

  termination_policies = ["OldestInstance"]

  # Because bootstrapping takes so long, we terminate manually in prod
  # We also would want to switch to an ELB health check before allowing AWS
  # to automatically terminate instances. Right now the ASG can't tell if
  # instance bootstrapping completed successfully.
  # https://github.com/18F/identity-devops-private/issues/337
  protect_from_scale_in = var.asg_prevent_auto_terminate == 1 ? true : false

  enabled_metrics = var.asg_enabled_metrics

  tag {
    key                 = "Name"
    value               = "asg-${var.env_name}-pivcac"
    propagate_at_launch = true
  }
  tag {
    key                 = "client"
    value               = var.client
    propagate_at_launch = true
  }
  tag {
    key                 = "prefix"
    value               = "pivcac"
    propagate_at_launch = true
  }
  tag {
    key                 = "domain"
    value               = "${var.env_name}.${var.root_domain}"
    propagate_at_launch = true
  }

  depends_on = [
    aws_autoscaling_group.outboundproxy,
    aws_autoscaling_group.migration,
  ]
}

resource "aws_elb" "pivcac" {
  name            = "${var.env_name}-pivcac"
  security_groups = [aws_security_group.web.id]
  subnets         = [aws_subnet.alb1.id, aws_subnet.alb2.id]

  access_logs {
    bucket        = "login-gov.elb-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
    bucket_prefix = "${var.env_name}/pivcac"
  }

  listener {
    instance_port     = 443
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"
  }

  health_check {
    target              = "HTTPS:443/health_check"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 10
    timeout             = 3
  }
}

resource "aws_s3_bucket" "pivcac_cert_bucket" {
  bucket = "login-gov-pivcac-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"

  tags = {
    Name = "login-gov-pivcac-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"
  }
  policy = data.aws_iam_policy_document.pivcac_bucket_policy.json

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket" "pivcac_public_cert_bucket" {
  bucket = "login-gov-pivcac-public-cert-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"

  tags = {
    Name = "login-gov-pivcac-public-cert-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"
  }
  policy = data.aws_iam_policy_document.pivcac_public_cert_bucket_policy.json

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "expiration"
    enabled = true

    noncurrent_version_expiration {
      days = 60
    }

    expiration {
      days = 60
    }
  }
}

module "pivcac_cert_bucket_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=7e11ebe24e3a9cbc34d1413cf4d20b3d71390d5b"
  #source = "../../../identity-terraform/s3_config"
  depends_on = [aws_s3_bucket.pivcac_cert_bucket]

  bucket_name_override = aws_s3_bucket.pivcac_cert_bucket.id
  region               = var.region
  inventory_bucket_arn = local.inventory_bucket_arn
}


module "pivcac_public_cert_bucket_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=7e11ebe24e3a9cbc34d1413cf4d20b3d71390d5b"
  #source = "../../../identity-terraform/s3_config"
  depends_on = [aws_s3_bucket.pivcac_public_cert_bucket]

  bucket_name_override = aws_s3_bucket.pivcac_public_cert_bucket.id
  region               = var.region
  inventory_bucket_arn = local.inventory_bucket_arn
}

data "aws_iam_policy_document" "pivcac_bucket_policy" {
  # allow pivcac hosts to read and write their SSL certs
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectAcl",
    ]
    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.pivcac.arn,
      ]
    }

    resources = [
      "arn:aws:s3:::login-gov-pivcac-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}",
      "arn:aws:s3:::login-gov-pivcac-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}/*",
    ]
  }
}

data "aws_iam_policy_document" "pivcac_public_cert_bucket_policy" {
  statement {
    actions = [
      "s3:PutObject",
    ]
    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.pivcac.arn,
      ]
    }

    resources = [
      "arn:aws:s3:::login-gov-pivcac-public-cert-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}",
      "arn:aws:s3:::login-gov-pivcac-public-cert-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}/*",
    ]
  }
}

# TODO - The following should be switched to count gated in TF 13
# and asg_name and elb_name should be set from introspection.
#
# This temp solution will create alarms using the expected names.
# If they are not present the alerts will not fire.
module "pivcac_insufficent_instances_alerts" {
  source = "../modules/asg_insufficent_instances_alerts"

  asg_name = "${var.env_name}-pivcac"

  alarm_actions = local.high_priority_alarm_actions
}

module "pivcac_unhealthy_instances_alerts" {
  source = "../modules/elb_unhealthy_instances_alerts"

  asg_name = "${var.env_name}-pivcac"
  elb_name = "${var.env_name}-pivcac"

  alarm_actions = local.low_priority_alarm_actions
}
