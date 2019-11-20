module "jumphost_user_data" {
  source = "../terraform-modules/bootstrap/"

  role   = "jumphost"
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

module "jumphost_lifecycle_hooks" {
  source   = "github.com/18F/identity-terraform//asg_lifecycle_notifications?ref=1db3ba569822d7803f2f6701fab5bc3242e2bb36"
  asg_name = aws_autoscaling_group.jumphost.name
}

module "jumphost_launch_template" {
  source = "github.com/18F/identity-terraform//launch_template?ref=1db3ba569822d7803f2f6701fab5bc3242e2bb36"

  role           = "jumphost"
  env            = var.env_name
  root_domain    = var.root_domain
  ami_id_map     = var.ami_id_map
  default_ami_id = local.account_default_ami_id

  instance_type             = var.instance_type_jumphost
  iam_instance_profile_name = aws_iam_instance_profile.base-permissions.name
  security_group_ids        = [aws_security_group.jumphost.id, aws_security_group.base.id]

  user_data = module.jumphost_user_data.rendered_cloudinit_config

  template_tags = {
    main_git_ref = module.jumphost_user_data.main_git_ref
  }
}

resource "aws_autoscaling_group" "jumphost" {
  name = "${var.env_name}-jumphost"

  launch_template {
    id      = module.jumphost_launch_template.template_id
    version = "$Latest"
  }

  min_size         = 0
  max_size         = 4 # TODO count subnets or Region's AZ width
  desired_capacity = var.asg_jumphost_desired

  wait_for_capacity_timeout = 0 # 0 == ignore

  # TODO use certificates instead of host keys
  # see http://man.openbsd.org/ssh-keygen#CERTIFICATES and Issue #621
  load_balancers = [aws_elb.jumphost.name]

  # https://github.com/18F/identity-devops-private/issues/259
  vpc_zone_identifier = [
    aws_subnet.jumphost1.id,
    aws_subnet.jumphost2.id,
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 0
  termination_policies      = ["OldestInstance"]

  # tags on the instance will come from the launch template
  tag {
    key                 = "prefix"
    value               = "jumphost"
    propagate_at_launch = false
  }
  tag {
    key                 = "domain"
    value               = "${var.env_name}.${var.root_domain}"
    propagate_at_launch = false
  }

  # We manually terminate instances in prod
  protect_from_scale_in = var.asg_prevent_auto_terminate
}

