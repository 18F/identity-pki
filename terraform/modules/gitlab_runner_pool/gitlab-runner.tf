module "gitlab_runner_user_data" {
  source = "../bootstrap/"

  role          = "gitlab_runner"
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

module "gitlab_runner_lifecycle_hooks" {
  source   = "github.com/18F/identity-terraform//asg_lifecycle_notifications?ref=e678ebc2c6e367b294e4d3a298da9c716d93146b"
  asg_name = aws_autoscaling_group.gitlab_runner.name
}

module "gitlab_runner_launch_template" {
  source = "github.com/18F/identity-terraform//launch_template?ref=e678ebc2c6e367b294e4d3a298da9c716d93146b"
  #source = "../../../identity-terraform/launch_template"
  role           = "gitlab_runner"
  env            = var.env_name
  root_domain    = var.root_domain
  ami_id_map     = var.ami_id_map
  default_ami_id = local.account_default_ami_id

  instance_type             = var.instance_type_gitlab_runner
  use_spot_instances        = var.use_spot_instances
  iam_instance_profile_name = aws_iam_instance_profile.gitlab_runner.name
  security_group_ids        = [aws_security_group.gitlab_runner.id, var.base_security_group_id]

  user_data = module.gitlab_runner_user_data.rendered_cloudinit_config

  instance_tags = {
    gitlab_runner_pool_name = var.gitlab_runner_pool_name,
  }

  template_tags = {
    main_git_ref = module.gitlab_runner_user_data.main_git_ref,
  }
}

resource "aws_autoscaling_group" "gitlab_runner" {
  name_prefix = "${var.env_name}-gitlab_runner"

  launch_template {
    id      = module.gitlab_runner_launch_template.template_id
    version = "$Latest"
  }

  min_size         = 1
  max_size         = 4 # TODO count subnets or Region's AZ width
  desired_capacity = var.asg_gitlab_runner_desired

  wait_for_capacity_timeout = 0 # 0 == ignore

  # https://github.com/18F/identity-devops-private/issues/259
  vpc_zone_identifier = [
    var.gitlab_subnet_1_id,
    var.gitlab_subnet_2_id,
  ]

  health_check_type         = "EC2"
  health_check_grace_period = 1
  termination_policies      = ["OldestInstance"]

  # tags on the instance will come from the launch template
  tag {
    key                 = "Name"
    value               = "gitlab_runner"
    propagate_at_launch = false
  }
  tag {
    key                 = "domain"
    value               = "${var.env_name}.${var.root_domain}"
    propagate_at_launch = false
  }
  tag {
    key                 = "environment"
    value               = var.env_name
    propagate_at_launch = false
  }

  # We manually terminate instances in prod
  protect_from_scale_in = var.asg_prevent_auto_terminate == 1 ? true : false
}
