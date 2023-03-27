module "gitlab_user_data" {
  source = "../../modules/bootstrap/"

  role                   = "gitlab"
  env                    = var.env_name
  domain                 = var.root_domain
  sns_topic_arn          = var.slack_events_sns_hook_arn
  s3_secrets_bucket_name = data.aws_s3_bucket.secrets.bucket

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
  no_proxy_hosts      = local.no_proxy_hosts
  proxy_enabled_roles = var.proxy_enabled_roles
}

module "gitlab_lifecycle_hooks" {
  source   = "github.com/18F/identity-terraform//asg_lifecycle_notifications?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  asg_name = aws_autoscaling_group.gitlab.name
}

module "gitlab_launch_template" {
  source = "github.com/18F/identity-terraform//launch_template?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/launch_template"
  role           = "gitlab"
  env            = var.env_name
  root_domain    = var.root_domain
  ami_id_map     = var.ami_id_map
  default_ami_id = local.default_base_ami_id

  instance_type             = var.instance_type_gitlab
  use_spot_instances        = var.use_spot_instances
  iam_instance_profile_name = aws_iam_instance_profile.gitlab.name
  security_group_ids        = [aws_security_group.gitlab.id, aws_security_group.base.id]

  user_data = module.gitlab_user_data.rendered_cloudinit_config

  template_tags = {
    main_git_ref = module.gitlab_user_data.main_git_ref
  }
}

resource "aws_autoscaling_group" "gitlab" {
  name              = "${var.env_name}-gitlab"
  target_group_arns = [aws_lb_target_group.gitlab.arn, aws_lb_target_group.gitlab-ssh.arn]

  launch_template {
    id      = module.gitlab_launch_template.template_id
    version = "$Latest"
  }

  min_size         = 1
  max_size         = 1 # TODO count subnets or Region's AZ width
  desired_capacity = var.asg_gitlab_desired

  wait_for_capacity_timeout = 0 # 0 == ignore

  # https://github.com/18F/identity-devops-private/issues/259
  vpc_zone_identifier = [aws_subnet.apps["a"].id]

  health_check_type         = "EC2"
  health_check_grace_period = 1
  termination_policies      = ["OldestInstance"]

  # tags on the instance will come from the launch template
  tag {
    key                 = "prefix"
    value               = "gitlab"
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
  tag {
    key                 = "fisma"
    value               = var.fisma_tag
    propagate_at_launch = true
  }

  # We manually terminate instances in prod
  protect_from_scale_in = var.asg_prevent_auto_terminate == 1 ? true : false
}

resource "aws_ebs_volume" "gitlab" {
  # XXX gitlab only can live in one AZ because of the EBS volume.
  availability_zone = var.gitlab_az
  size              = 20
  encrypted         = true

  tags = {
    Name = "${var.name}-gitlab-${var.env_name}"
  }
}

resource "aws_s3_object" "gitlab_volume_id" {
  bucket  = data.aws_s3_bucket.secrets.id
  key     = "${var.env_name}/gitlab_ebs_volume"
  content = aws_ebs_volume.gitlab.id

  source_hash = md5(aws_ebs_volume.gitlab.id)
}
