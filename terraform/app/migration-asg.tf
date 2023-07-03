module "migration_user_data" {
  source = "../modules/bootstrap/"

  role                   = "migration"
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

module "migration_launch_template" {
  source = "github.com/18F/identity-terraform//launch_template?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/launch_template"
  role           = "migration"
  env            = var.env_name
  root_domain    = var.root_domain
  ami_id_map     = var.ami_id_map
  default_ami_id = local.account_rails_ami_id

  instance_type             = var.instance_type_migration
  iam_instance_profile_name = aws_iam_instance_profile.migration.name
  security_group_ids        = [aws_security_group.migration.id, aws_security_group.base.id]

  user_data = module.migration_user_data.rendered_cloudinit_config

  template_tags = {
    main_git_ref = module.migration_user_data.main_git_ref
  }
}

resource "aws_autoscaling_group" "migration" {
  name = "${var.env_name}-migration"

  launch_template {
    id      = module.migration_launch_template.template_id
    version = "$Latest"
  }

  min_size         = var.asg_migration_min
  max_size         = var.asg_migration_max
  desired_capacity = var.asg_migration_desired

  wait_for_capacity_timeout = 0

  target_group_arns = []

  vpc_zone_identifier = [for subnet in aws_subnet.app : subnet.id]

  # possible choices: EC2, ELB
  health_check_type = "EC2"

  health_check_grace_period = 1

  termination_policies = ["OldestInstance"]

  # Migration servers never serve production traffic, so are not protected
  # from scale-in.
  protect_from_scale_in = false

  enabled_metrics = var.asg_enabled_metrics

  # tags on the instance will come from the launch template
  tag {
    key                 = "prefix"
    value               = "migration"
    propagate_at_launch = false
  }
  tag {
    key                 = "domain"
    value               = "${var.env_name}.${var.root_domain}"
    propagate_at_launch = false
  }
  # utility tag to skip asg_recycle ALL
  tag {
    key                 = "utility"
    value               = "true"
    propagate_at_launch = true
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

module "migration_lifecycle_hooks" {
  source = "github.com/18F/identity-terraform//asg_lifecycle_notifications?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/asg_lifecycle_notifications"
  asg_name = aws_autoscaling_group.migration.name
}

module "migration_recycle" {
  source = "github.com/18F/identity-terraform//asg_recycle?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/asg_recycle"

  asg_name       = aws_autoscaling_group.migration.name
  normal_min     = var.asg_migration_min
  normal_max     = var.asg_migration_max
  normal_desired = 1
  time_zone      = var.autoscaling_time_zone

  scale_schedule  = var.autoscaling_schedule_name
  custom_schedule = local.migration_rotation_schedules # migration-schedule.tf

  # Hard set 1 instance for spin up and none for spin down
  spinup_mult_factor         = 1
  override_spindown_capacity = 0
}

