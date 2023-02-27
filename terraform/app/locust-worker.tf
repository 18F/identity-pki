module "locust_worker_lifecycle_hooks" {
  count  = var.enable_loadtesting ? 1 : 0
  source = "github.com/18F/identity-terraform//asg_lifecycle_notifications?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/asg_lifecycle_notifications"
  asg_name = aws_autoscaling_group.locust_worker[0].name
}

module "locust_worker_launch_template" {
  count  = var.enable_loadtesting ? 1 : 0
  source = "github.com/18F/identity-terraform//launch_template?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/launch_template"
  role           = "locust-worker"
  env            = var.env_name
  root_domain    = var.root_domain
  ami_id_map     = var.ami_id_map
  default_ami_id = local.account_default_ami_id

  instance_type             = var.instance_type_locust
  use_spot_instances        = var.use_spot_instances
  iam_instance_profile_name = aws_iam_instance_profile.base-permissions.name
  security_group_ids        = [aws_security_group.locust[0].id, aws_security_group.base.id]

  user_data = module.locust_user_data[0].rendered_cloudinit_config

  template_tags = {
    main_git_ref = module.locust_user_data[0].main_git_ref
  }
}

resource "aws_autoscaling_group" "locust_worker" {
  count = var.enable_loadtesting ? 1 : 0
  name  = "${var.env_name}-locust-worker"

  launch_template {
    id      = module.locust_worker_launch_template[0].template_id
    version = "$Latest"
  }

  min_size         = 0
  max_size         = var.asg_locust_worker_max
  desired_capacity = var.asg_locust_worker_desired

  wait_for_capacity_timeout = 0

  vpc_zone_identifier = [for subnet in aws_subnet.app : subnet.id]

  health_check_type         = "EC2"
  health_check_grace_period = 1
  termination_policies      = ["OldestInstance"]

  # tags on the instance will come from the launch template
  tag {
    key                 = "prefix"
    value               = "locust-worker"
    propagate_at_launch = false
  }
  tag {
    key                 = "domain"
    value               = "${var.env_name}.${var.root_domain}"
    propagate_at_launch = false
  }

  # We manually terminate instances in prod
  protect_from_scale_in = var.asg_prevent_auto_terminate == 1 ? true : false

  depends_on = [aws_autoscaling_group.outboundproxy]
}
