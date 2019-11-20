module "elk_user_data" {
  source = "../terraform-modules/bootstrap/"

  role   = "elk"
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

module "elk_lifecycle_hooks" {
  source   = "github.com/18F/identity-terraform//asg_lifecycle_notifications?ref=0e2e1bc96c3dc13806c0c1a330098c242e52a544"
  asg_name = aws_autoscaling_group.elk.name
}

module "elk_launch_template" {
  source = "github.com/18F/identity-terraform//launch_template?ref=0e2e1bc96c3dc13806c0c1a330098c242e52a544"

  role           = "elk"
  env            = var.env_name
  root_domain    = var.root_domain
  ami_id_map     = var.ami_id_map
  default_ami_id = local.account_default_ami_id

  instance_type             = var.instance_type_elk
  iam_instance_profile_name = aws_iam_instance_profile.elk_instance_profile.name
  security_group_ids        = [aws_security_group.elk.id, aws_security_group.base.id]

  user_data = module.elk_user_data.rendered_cloudinit_config

  template_tags = {
    main_git_ref    = module.elk_user_data.main_git_ref
    private_git_ref = module.elk_user_data.private_git_ref
  }
}

resource "aws_autoscaling_group" "elk" {
  name = "${var.env_name}-elk"

  launch_template {
    id      = module.elk_launch_template.template_id
    version = "$Latest"
  }

  min_size         = 0
  max_size         = 8
  desired_capacity = var.asg_elk_desired

  wait_for_capacity_timeout = 0

  vpc_zone_identifier = aws_subnet.elk.*.id

  # https://github.com/18F/identity-devops-private/issues/631
  health_check_type         = "EC2"
  health_check_grace_period = 0

  termination_policies = ["OldestInstance"]

  load_balancers = [aws_elb.elk.id]

  protect_from_scale_in = var.asg_prevent_auto_terminate

  # tags on the instance will come from the launch template
  tag {
    key                 = "prefix"
    value               = "elk"
    propagate_at_launch = false
  }
  tag {
    key                 = "domain"
    value               = "${var.env_name}.${var.root_domain}"
    propagate_at_launch = false
  }
}

