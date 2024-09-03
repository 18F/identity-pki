module "analytics_user_data" {
  source = "../../modules/bootstrap/"

  role                   = "analytics"
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

  # proxy settings
  proxy_server        = var.proxy_server
  proxy_port          = var.proxy_port
  no_proxy_hosts      = local.no_proxy_hosts
  proxy_enabled_roles = var.proxy_enabled_roles
}

module "analytics_launch_template" {
  source = "github.com/18F/identity-terraform//launch_template?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/launch_template"
  role           = "analytics"
  env            = var.env_name
  root_domain    = var.root_domain
  ami_id_map     = var.ami_id_map
  default_ami_id = var.rails_ami_analytics_sandbox_uw2

  instance_type             = var.instance_type_analytics
  iam_instance_profile_name = aws_iam_instance_profile.analytics.name
  security_group_ids        = [aws_security_group.analytics.id, aws_security_group.base.id]
  user_data                 = module.analytics_user_data.rendered_cloudinit_config

  use_spot_instances = var.use_spot_instances

  template_tags = {
    main_git_ref = module.analytics_user_data.main_git_ref
  }
}

module "analytics_lifecycle_hooks" {
  source = "github.com/18F/identity-terraform//asg_lifecycle_notifications?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/asg_lifecycle_notifications"
  asg_name = aws_autoscaling_group.analytics.name
}

module "analytics_recycle" {
  source = "github.com/18F/identity-terraform//asg_recycle?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/asg_recycle"

  asg_name       = aws_autoscaling_group.analytics.name
  normal_min     = var.asg_analytics_min
  normal_max     = var.asg_analytics_max
  normal_desired = var.asg_analytics_desired
  scale_schedule = var.autoscaling_schedule_name
  time_zone      = var.autoscaling_time_zone
}

resource "aws_autoscaling_group" "analytics" {
  name = "${var.env_name}-analytics"

  launch_template {
    id      = module.analytics_launch_template.template_id
    version = "$Latest"
  }

  min_size         = var.asg_analytics_min
  max_size         = var.asg_analytics_max
  desired_capacity = var.asg_analytics_desired

  wait_for_capacity_timeout = 0

  lifecycle {
    create_before_destroy = true
  }

  target_group_arns = [
    aws_lb_target_group.analytics.arn,
  ]

  vpc_zone_identifier = [for zone in local.network_zones : aws_subnet.apps[zone].id]

  health_check_type         = "ELB"
  health_check_grace_period = 1

  termination_policies = ["OldestInstance"]

  protect_from_scale_in = var.asg_prevent_auto_terminate == 1 ? true : false

  enabled_metrics = var.asg_enabled_metrics

  # tags on the instance will come from the launch template
  tag {
    key                 = "prefix"
    value               = "analytics"
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
    module.outbound_proxy.proxy_asg_name,
  ]
}

resource "aws_autoscaling_policy" "analytics" {
  count                     = var.analytics_cpu_autoscaling_enabled
  name                      = "${var.env_name}-analytics-cpu"
  autoscaling_group_name    = aws_autoscaling_group.analytics.name
  estimated_instance_warmup = 900

  policy_type = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.analytics_cpu_autoscaling_target
  }
}
