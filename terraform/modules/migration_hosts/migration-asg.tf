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
  var.bootstrap_main_git_ref_default) : "stages/${var.env_name}"

  no_proxy_hosts = var.no_proxy_hosts != "" ? var.no_proxy_hosts : join(",", concat([
    "localhost",
    "127.0.0.1",
    "169.254.169.254",
    "169.254.169.123",
    ".login.gov.internal",
    "metadata.google.internal",
    ], formatlist("%s.${var.region}.amazonaws.com", [
      "ec2",
      "ec2messages",
      "events",
      "kms",
      "lambda",
      "secretsmanager",
      "sns",
      "sqs",
      "ssm",
      "ssmmessages",
      "sts",
  ])))
}

module "migration_user_data" {
  source = "../../modules/bootstrap/"

  role                   = "migration"
  env                    = var.env_name
  domain                 = var.root_domain
  s3_secrets_bucket_name = var.s3_secrets_bucket_name
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
  no_proxy_hosts      = local.no_proxy_hosts
  proxy_enabled_roles = var.proxy_enabled_roles
}

module "migration_launch_template" {
  source = "github.com/18F/identity-terraform//launch_template?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/launch_template"
  role           = "migration"
  env            = var.env_name
  root_domain    = var.root_domain
  ami_id_map     = var.ami_id_map
  default_ami_id = var.rails_ami_id

  instance_type             = var.instance_type_migration
  iam_instance_profile_name = var.migration_instance_profile
  security_group_ids        = [aws_security_group.migration.id, var.base_security_group_id]

  user_data = module.migration_user_data.rendered_cloudinit_config

  template_tags = {
    main_git_ref = module.migration_user_data.main_git_ref
  }
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
  custom_schedule = var.migration_rotation_schedules

  # Hard set 1 instance for spin up and none for spin down
  spinup_mult_factor         = 1
  override_spindown_capacity = 0
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

  vpc_zone_identifier = var.migration_subnet_ids

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
}