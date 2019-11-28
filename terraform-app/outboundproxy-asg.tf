module "outboundproxy_user_data" {
  source = "../terraform-modules/bootstrap/"

  role   = "outboundproxy"
  env    = var.env_name
  domain = var.root_domain

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

  # the outboundproxy should never use a proxy
  proxy_server        = ""
  proxy_port          = ""
  no_proxy_hosts      = ""
  proxy_enabled_roles = var.proxy_enabled_roles
}

resource "aws_iam_role" "obproxy" {
  name               = "${var.env_name}_obproxy_iam_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_from_vpc.json
}

resource "aws_iam_instance_profile" "obproxy" {
  name = "${var.env_name}_obproxy_instance_profile"
  role = aws_iam_role.obproxy.name
}

resource "aws_iam_role_policy" "obproxy-secrets" {
  name   = "${var.env_name}-obproxy-secrets"
  role   = aws_iam_role.obproxy.id
  policy = data.aws_iam_policy_document.secrets_role_policy.json
}

resource "aws_iam_role_policy" "obproxy-certificates" {
  name   = "${var.env_name}-obproxy-certificates"
  role   = aws_iam_role.obproxy.id
  policy = data.aws_iam_policy_document.certificates_role_policy.json
}

resource "aws_iam_role_policy" "obproxy-describe_instances" {
  name   = "${var.env_name}-obproxy-describe_instances"
  role   = aws_iam_role.obproxy.id
  policy = data.aws_iam_policy_document.describe_instances_role_policy.json
}

resource "aws_iam_role_policy" "obproxy-cloudwatch-logs" {
  name   = "${var.env_name}-obproxy-cloudwatch-logs"
  role   = aws_iam_role.obproxy.id
  policy = data.aws_iam_policy_document.cloudwatch-logs.json
}

resource "aws_iam_role_policy" "obproxy-auto-eip" {
  name   = "${var.env_name}-obproxy-auto-eip"
  role   = aws_iam_role.obproxy.id
  policy = data.aws_iam_policy_document.auto_eip_policy.json
}

module "outboundproxy_launch_template" {
  source = "github.com/18F/identity-terraform//launch_template?ref=379b9ca062233ddf26b69c021b7a8546532ec934"

  role           = "outboundproxy"
  env            = var.env_name
  root_domain    = var.root_domain
  ami_id_map     = var.ami_id_map
  default_ami_id = local.account_default_ami_id

  instance_type             = var.instance_type_outboundproxy
  iam_instance_profile_name = aws_iam_instance_profile.obproxy.name
  security_group_ids        = [aws_security_group.obproxy.id, aws_security_group.base.id]
  user_data                 = module.outboundproxy_user_data.rendered_cloudinit_config

  template_tags = {
    main_git_ref = module.outboundproxy_user_data.main_git_ref
  }
}

module "obproxy_lifecycle_hooks" {
  source   = "github.com/18F/identity-terraform//asg_lifecycle_notifications?ref=379b9ca062233ddf26b69c021b7a8546532ec934"
  asg_name = aws_autoscaling_group.outboundproxy.name
}

module "outboundproxy_recycle" {
  source = "github.com/18F/identity-terraform//asg_recycle?ref=379b9ca062233ddf26b69c021b7a8546532ec934"

  # switch to count when that's a thing that we can do
  # https://github.com/hashicorp/terraform/issues/953
  enabled = var.asg_auto_recycle_enabled

  use_daily_business_hours_schedule = var.asg_auto_recycle_use_business_schedule

  asg_name                = aws_autoscaling_group.outboundproxy.name
  normal_desired_capacity = aws_autoscaling_group.outboundproxy.desired_capacity
}

resource "aws_route53_record" "obproxy" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "obproxy.login.gov.internal"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.obproxy.dns_name]
}

resource "aws_autoscaling_group" "outboundproxy" {
  name = "${var.env_name}-outboundproxy"

  min_size         = var.asg_outboundproxy_min
  max_size         = var.asg_outboundproxy_max
  desired_capacity = var.asg_outboundproxy_desired

  wait_for_capacity_timeout = 0

  lifecycle {
    create_before_destroy = true
  }

  vpc_zone_identifier = [
    aws_subnet.publicsubnet1.id,
    aws_subnet.publicsubnet2.id,
    aws_subnet.publicsubnet3.id,
  ]

  target_group_arns = [aws_lb_target_group.obproxy.arn]

  health_check_type         = "EC2"
  health_check_grace_period = 0

  termination_policies = ["OldestInstance"]

  # We manually terminate instances in prod
  protect_from_scale_in = var.asg_prevent_auto_terminate == 1 ? true : false

  launch_template {
    id      = module.outboundproxy_launch_template.template_id
    version = "$Latest"
  }

  # tags on the instance will come from the launch template
  tag {
    key                 = "prefix"
    value               = "outboundproxy"
    propagate_at_launch = false
  }
  tag {
    key                 = "domain"
    value               = "${var.env_name}.${var.root_domain}"
    propagate_at_launch = false
  }
}

# This module creates cloudwatch logs filters that create metrics for squid
# total requests and denied requests. It also creates an alarm on denied
# requests that notifies to the specified alarm SNS ARN.
module "outboundproxy_cloudwatch_filters" {
  source = "github.com/18F/identity-terraform//squid_cloudwatch_filters?ref=379b9ca062233ddf26b69c021b7a8546532ec934"

  env_name      = var.env_name
  alarm_actions = [var.slack_events_sns_hook_arn] # notify slack on denied requests
}

