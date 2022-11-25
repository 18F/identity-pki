locals {
  secrets_bucket = join(".", [
    "login-gov.secrets",
    "${data.aws_caller_identity.current.account_id}-${var.region}"
  ])

  bootstrap_private_s3_ssh_key_url = var.bootstrap_private_s3_ssh_key_url != "" ? (
    var.bootstrap_private_s3_ssh_key_url
  ) : "s3://${local.secrets_bucket}/common/id_ecdsa.id-do-private.deploy"
  bootstrap_private_git_ref = var.bootstrap_private_git_ref != "" ? (
  var.bootstrap_private_git_ref) : "main"

  bootstrap_main_s3_ssh_key_url = var.bootstrap_main_s3_ssh_key_url != "" ? (
    var.bootstrap_main_s3_ssh_key_url
  ) : "s3://${local.secrets_bucket}/common/id_ecdsa.identity-devops.deploy"
  bootstrap_main_git_ref_default = var.bootstrap_main_git_ref_default != "" ? (
  var.bootstrap_main_git_ref_default) : "stages/gitlab${var.env_name}"

  account_default_ami_id = var.default_ami_id_tooling
}

module "outboundproxy_user_data" {
  source = "../../modules/bootstrap/"

  role          = "outboundproxy"
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

  # the outboundproxy should never use a proxy
  proxy_server        = ""
  proxy_port          = ""
  no_proxy_hosts      = ""
  proxy_enabled_roles = var.proxy_enabled_roles
}

module "outboundproxy_launch_template" {
  source = "github.com/18F/identity-terraform//launch_template?ref=5d344d205dd09eb85d5de1ff1081c4a598afe433"
  #source = "../../../identity-terraform/launch_template"
  role           = "${var.proxy_for}-outboundproxy"
  env            = var.env_name
  root_domain    = var.root_domain
  ami_id_map     = var.ami_id_map
  default_ami_id = var.account_default_ami_id

  instance_type             = var.instance_type_outboundproxy
  use_spot_instances        = var.use_spot_instances
  iam_instance_profile_name = aws_iam_instance_profile.obproxy.name
  security_group_ids        = [aws_security_group.obproxy.id, var.base_security_group_id]
  user_data                 = module.outboundproxy_user_data.rendered_cloudinit_config

  instance_tags = {
    proxy_for = var.proxy_for
  }

  template_tags = {
    main_git_ref = module.outboundproxy_user_data.main_git_ref
  }
}

module "obproxy_lifecycle_hooks" {
  source   = "github.com/18F/identity-terraform//asg_lifecycle_notifications?ref=5d344d205dd09eb85d5de1ff1081c4a598afe433"
  asg_name = aws_autoscaling_group.outboundproxy.name
}

resource "aws_route53_record" "obproxy" {
  zone_id = var.route53_internal_zone_id
  name    = var.hostname
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.obproxy.dns_name]
}

resource "aws_autoscaling_group" "outboundproxy" {
  name_prefix = "${var.env_name}-${var.proxy_for}-obproxy"

  min_size         = var.asg_outboundproxy_min
  max_size         = var.asg_outboundproxy_max
  desired_capacity = var.asg_outboundproxy_desired

  wait_for_capacity_timeout = 0

  lifecycle {
    create_before_destroy = true
  }

  vpc_zone_identifier = var.proxy_subnet_ids

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

resource "aws_autoscaling_policy" "outboundproxy" {
  name                      = "${var.env_name}-obproxy-cpu"
  autoscaling_group_name    = aws_autoscaling_group.outboundproxy.name
  estimated_instance_warmup = 360

  policy_type = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 45
  }
}
