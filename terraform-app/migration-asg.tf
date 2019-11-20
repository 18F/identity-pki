resource "aws_iam_instance_profile" "migration" {
  name = "${var.env_name}-migration"
  role = aws_iam_role.idp.name # for now reuse the idp's role
}

module "migration_user_data" {
  source = "../terraform-modules/bootstrap/"

  role   = "migration"
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

  # proxy variables
  proxy_server        = var.proxy_server
  proxy_port          = var.proxy_port
  no_proxy_hosts      = var.no_proxy_hosts
  proxy_enabled_roles = var.proxy_enabled_roles
}

module "migration_launch_template" {
  source = "github.com/18F/identity-terraform//launch_template?ref=d1402b5b98174e9a8aa23f1be05b2a8e39223fd4"

  role           = "migration"
  env            = var.env_name
  root_domain    = var.root_domain
  ami_id_map     = var.ami_id_map
  default_ami_id = local.account_default_ami_id

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

  vpc_zone_identifier = [
    aws_subnet.idp1.id,
    aws_subnet.idp2.id,
  ]

  # possible choices: EC2, ELB
  health_check_type = "EC2"

  # The grace period starts after lifecycle hooks are done and the instance
  # is InService. Having a grace period is dangerous because the ASG
  # considers instances in the grace period to be healthy.
  health_check_grace_period = 0

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
}

module "migration_lifecycle_hooks" {
  source   = "github.com/18F/identity-terraform//asg_lifecycle_notifications?ref=2c43bfd79a8a2377657bc8ed4764c3321c0f8e80"
  asg_name = aws_autoscaling_group.migration.name
}

