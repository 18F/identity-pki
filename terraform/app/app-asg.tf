module "app_user_data" {
  count  = var.apps_enabled
  source = "../modules/bootstrap/"

  role                   = "app"
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

  # proxy variables
  proxy_server        = var.proxy_server
  proxy_port          = var.proxy_port
  no_proxy_hosts      = var.no_proxy_hosts
  proxy_enabled_roles = var.proxy_enabled_roles
}

module "app_lifecycle_hooks" {
  count  = var.apps_enabled
  source = "github.com/18F/identity-terraform//asg_lifecycle_notifications?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/asg_lifecycle_notifications"
  asg_name = aws_autoscaling_group.app[count.index].name
  enabled  = var.apps_enabled
}

module "app_launch_template" {
  count  = var.apps_enabled
  source = "github.com/18F/identity-terraform//launch_template?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/launch_template"

  role           = "app"
  env            = var.env_name
  root_domain    = var.root_domain
  ami_id_map     = var.ami_id_map
  default_ami_id = local.account_rails_ami_id

  instance_type             = var.instance_type_app
  use_spot_instances        = var.use_spot_instances
  iam_instance_profile_name = aws_iam_instance_profile.app[count.index].name
  security_group_ids        = [aws_security_group.app[count.index].id, module.base_security_uw2.base_id]

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
    module.outboundproxy_uw2.proxy_asg_name,
    aws_cloudwatch_log_group.nginx_access_log
  ]
}

module "app_recycle" {
  count  = var.apps_enabled
  source = "github.com/18F/identity-terraform//asg_recycle?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
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
  role  = module.application_iam_roles.app_iam_role_name
}