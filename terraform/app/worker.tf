module "worker_user_data" {
  source = "../modules/bootstrap/"

  role          = "worker"
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

  # proxy settings
  proxy_server        = var.proxy_server
  proxy_port          = var.proxy_port
  no_proxy_hosts      = var.no_proxy_hosts
  proxy_enabled_roles = var.proxy_enabled_roles
}

resource "aws_iam_role" "worker" {
  name               = "${var.env_name}_worker_iam_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_from_vpc.json
}

resource "aws_iam_instance_profile" "worker" {
  name = "${var.env_name}_worker_instance_profile"
  role = aws_iam_role.worker.name
}

resource "aws_iam_role_policy" "worker-secrets" {
  name   = "${var.env_name}-worker-secrets"
  role   = aws_iam_role.worker.id
  policy = data.aws_iam_policy_document.secrets_role_policy.json
}

resource "aws_iam_role_policy" "worker-certificates" {
  name   = "${var.env_name}-worker-certificates"
  role   = aws_iam_role.worker.id
  policy = data.aws_iam_policy_document.certificates_role_policy.json
}

resource "aws_iam_role_policy" "worker-describe_instances" {
  name   = "${var.env_name}-worker-describe_instances"
  role   = aws_iam_role.worker.id
  policy = data.aws_iam_policy_document.describe_instances_role_policy.json
}

resource "aws_iam_role_policy" "worker-cloudwatch-logs" {
  name   = "${var.env_name}-worker-cloudwatch-logs"
  role   = aws_iam_role.worker.id
  policy = data.aws_iam_policy_document.cloudwatch-logs.json
}

resource "aws_iam_role_policy" "worker-cloudwatch-agent" {
  name   = "${var.env_name}-worker-cloudwatch-agent"
  role   = aws_iam_role.worker.id
  policy = data.aws_iam_policy_document.cloudwatch-agent.json
}

resource "aws_iam_role_policy" "worker-ssm-access" {
  name   = "${var.env_name}-worker-ssm-access"
  role   = aws_iam_role.worker.id
  policy = data.aws_iam_policy_document.ssm_access_role_policy.json
}

resource "aws_iam_role_policy" "worker-sns-publish-alerts" {
  name   = "${var.env_name}-worker-sns-publish-alerts"
  role   = aws_iam_role.worker.id
  policy = data.aws_iam_policy_document.sns-publish-alerts-policy.json
}

module "worker_launch_template" {
  source = "github.com/18F/identity-terraform//launch_template?ref=819b7265d0ae14df6bf64159e2c8f116c2804c35"
  #source = "../../../identity-terraform/launch_template"
  role           = "worker"
  env            = var.env_name
  root_domain    = var.root_domain
  ami_id_map     = var.ami_id_map
  default_ami_id = local.account_rails_ami_id

  instance_type             = var.instance_type_worker
  use_spot_instances        = var.use_spot_instances
  iam_instance_profile_name = aws_iam_instance_profile.worker.name
  security_group_ids        = [aws_security_group.worker.id, aws_security_group.base.id]
  user_data                 = module.worker_user_data.rendered_cloudinit_config

  template_tags = {
    main_git_ref = module.worker_user_data.main_git_ref
  }
}

module "worker_lifecycle_hooks" {
  source   = "github.com/18F/identity-terraform//asg_lifecycle_notifications?ref=476ab4456e547e125dcd53cb6131419b54f1f476"
  asg_name = aws_autoscaling_group.worker.name
}

module "worker_recycle" {
  source = "github.com/18F/identity-terraform//asg_recycle?ref=476ab4456e547e125dcd53cb6131419b54f1f476"

  # switch to count when that's a thing that we can do
  # https://github.com/hashicorp/terraform/issues/953
  enabled = var.asg_auto_recycle_enabled

  use_daily_business_hours_schedule = var.asg_recycle_business_hours

  asg_name                = aws_autoscaling_group.worker.name
  normal_desired_capacity = aws_autoscaling_group.worker.desired_capacity
}

resource "aws_autoscaling_group" "worker" {
  name = "${var.env_name}-worker"

  min_size         = var.asg_worker_min
  max_size         = var.asg_worker_max
  desired_capacity = var.asg_worker_desired

  wait_for_capacity_timeout = 0

  lifecycle {
    create_before_destroy = true
  }

  vpc_zone_identifier = [
    aws_subnet.privatesubnet1.id,
    aws_subnet.privatesubnet2.id,
    aws_subnet.privatesubnet3.id,
  ]

  health_check_type         = "EC2"
  health_check_grace_period = 1

  termination_policies = ["OldestInstance"]

  # We manually terminate instances in prod
  protect_from_scale_in = var.asg_prevent_auto_terminate == 1 ? true : false

  launch_template {
    id      = module.worker_launch_template.template_id
    version = "$Latest"
  }

  # tags on the instance will come from the launch template
  tag {
    key                 = "prefix"
    value               = "worker"
    propagate_at_launch = false
  }
  tag {
    key                 = "domain"
    value               = "${var.env_name}.${var.root_domain}"
    propagate_at_launch = false
  }
}

resource "aws_autoscaling_policy" "worker" {
  name                      = "${var.env_name}-worker-cpu"
  autoscaling_group_name    = aws_autoscaling_group.worker.name
  estimated_instance_warmup = 360

  policy_type = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.idp_cpu_autoscaling_target
  }
}
