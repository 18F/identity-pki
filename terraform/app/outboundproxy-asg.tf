module "outboundproxy_user_data" {
  source = "../modules/bootstrap/"

  role                   = "outboundproxy"
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

  # the outboundproxy should never use a proxy
  proxy_server        = ""
  proxy_port          = ""
  no_proxy_hosts      = ""
  proxy_enabled_roles = var.proxy_enabled_roles
}

resource "aws_iam_instance_profile" "obproxy" {
  name = "${var.env_name}_obproxy_instance_profile"
  role = module.application_iam_roles.obproxy_iam_role_name
}

module "outboundproxy_launch_template" {
  source = "github.com/18F/identity-terraform//launch_template?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/launch_template"
  role           = "outboundproxy"
  env            = var.env_name
  root_domain    = var.root_domain
  ami_id_map     = var.ami_id_map
  default_ami_id = local.account_default_ami_id

  instance_type             = var.instance_type_outboundproxy
  use_spot_instances        = var.use_spot_instances
  iam_instance_profile_name = aws_iam_instance_profile.obproxy.name
  security_group_ids        = [aws_security_group.obproxy.id, aws_security_group.base.id]
  user_data                 = module.outboundproxy_user_data.rendered_cloudinit_config

  template_tags = {
    main_git_ref = module.outboundproxy_user_data.main_git_ref
  }
}

module "obproxy_lifecycle_hooks" {
  source = "github.com/18F/identity-terraform//asg_lifecycle_notifications?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/asg_lifecycle_notifications"
  asg_name = aws_autoscaling_group.outboundproxy.name
}

module "outboundproxy_recycle" {
  source = "github.com/18F/identity-terraform//asg_recycle?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/asg_recycle"

  asg_name       = aws_autoscaling_group.outboundproxy.name
  normal_min     = var.asg_outboundproxy_min
  normal_max     = var.asg_outboundproxy_max
  normal_desired = var.asg_outboundproxy_desired
  time_zone      = var.autoscaling_time_zone

  scale_schedule  = var.autoscaling_schedule_name
  custom_schedule = local.outboundproxy_rotation_schedules # outboundproxy-schedule.tf
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

  vpc_zone_identifier = [for subnet in aws_subnet.app : subnet.id]

  target_group_arns = [aws_lb_target_group.obproxy.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 1

  enabled_metrics = var.asg_enabled_metrics

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
  tag {
    key                 = "fisma"
    value               = var.fisma_tag
    propagate_at_launch = true
  }
}

# This module creates cloudwatch logs filters that create metrics for squid
# total requests and denied requests. It also creates an alarm on denied
# creates alarm on total requests following below a threshold
# requests that notifies to the specified alarm SNS ARN.
module "outboundproxy_cloudwatch_filters" {
  source = "github.com/18F/identity-terraform//squid_cloudwatch_filters?ref=49bc02749966cef8ec7f14c4d181a2d3879721fc"
  #source = "../../../identity-terraform/squid_cloudwatch_filters"
  depends_on = [aws_cloudwatch_log_group.squid_access_log]

  env_name      = var.env_name
  alarm_actions = [var.slack_events_sns_hook_arn] # notify slack on denied requests
}
