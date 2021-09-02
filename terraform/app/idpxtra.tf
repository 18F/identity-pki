# Dedicated IdP pool for Small Business Administration
module "idpxtra_launch_template" {
  source = "github.com/18F/identity-terraform//launch_template?ref=8f0abe0e3708e2c1ef1c1653ae2b57b378bf8dbf"
  #source = "../../../identity-terraform/launch_template"
  role           = "idpxtra"
  env            = var.env_name
  root_domain    = var.root_domain
  ami_id_map     = var.ami_id_map
  default_ami_id = local.account_rails_ami_id

  instance_type             = var.instance_type_idp
  use_spot_instances        = var.use_spot_instances
  iam_instance_profile_name = aws_iam_instance_profile.idp.name
  security_group_ids        = [aws_security_group.idp.id, aws_security_group.base.id]

  user_data = module.idp_user_data.rendered_cloudinit_config

  template_tags = {
    main_git_ref = module.idp_user_data.main_git_ref
  }
}

resource "aws_alb_target_group" "idpxtra" {
  depends_on = [aws_alb.idp]

  health_check {
    # we have HTTP basic auth enabled in nonprod envs in the prod AWS account
    matcher  = "200"
    protocol = "HTTPS"

    interval            = 10
    timeout             = 5
    healthy_threshold   = 9 # up for 90 seconds
    unhealthy_threshold = 2 # down for 20 seconds
  }

  name     = "${var.env_name}-idpxtra-ssl"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = aws_vpc.default.id

  deregistration_delay = 120

  tags = {
    prefix      = var.env_name
    health_role = "idp"
  }
}

resource "aws_lb_listener_rule" "idpxtra_client_id_query" {
  # Match against query string
  for_each = var.idpxtra_client_ids

  depends_on = [aws_alb_target_group.idpxtra]

  listener_arn = aws_alb_listener.idp-ssl.id

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.idpxtra.arn
  }

  # Match client_id portion of query string
  condition {
    query_string {
      key   = "client_id"
      value = each.value
    }
  }
}

resource "aws_lb_listener_rule" "idpxtra_client_id_cookie" {
  # Match against cookie
  for_each = var.idpxtra_client_ids

  depends_on = [aws_alb_target_group.idpxtra]

  listener_arn = aws_alb_listener.idp-ssl.id

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.idpxtra.arn
  }

  # Match ARN (raw or urlencoded) in cookie
  condition {
    http_header {
      http_header_name = "cookie"
      values = [
        "*sp_issuer=${each.value}*",
        "*sp_issuer=${urlencode(each.value)}*"
      ]
    }
  }
}

resource "aws_lb_listener_rule" "idpxtra_sp_network" {
  # Match against CIDR
  for_each = var.idpxtra_sp_networks

  depends_on = [aws_alb_target_group.idpxtra]

  listener_arn = aws_alb_listener.idp-ssl.id

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.idpxtra.arn
  }

  # Match source IP CIDR block
  condition {
    source_ip {
      values = each.value
    }
  }
}

resource "aws_autoscaling_group" "idpxtra" {
  name = "${var.env_name}-idpxtra"

  launch_template {
    id      = module.idpxtra_launch_template.template_id
    version = "$Latest"
  }

  min_size         = var.asg_idpxtra_min
  max_size         = var.asg_idpxtra_max
  desired_capacity = var.asg_idpxtra_desired

  wait_for_capacity_timeout = 0

  target_group_arns = [
    aws_alb_target_group.idpxtra.arn
  ]

  # Place in shared public blocks accross 3 AZs
  # TODO - See https://github.com/18F/identity-devops/issues/2084
  vpc_zone_identifier = [
    aws_subnet.privatesubnet1.id,
    aws_subnet.privatesubnet2.id,
    aws_subnet.privatesubnet3.id,
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 1

  termination_policies = ["OldestInstance"]

  # Because bootstrapping takes so long, we terminate manually in prod
  # More context on ASG deploys and safety:
  # https://github.com/18F/identity-devops-private/issues/337
  protect_from_scale_in = var.asg_prevent_auto_terminate == 1 ? true : false

  enabled_metrics = var.asg_enabled_metrics

  # tags on the instance will come from the launch template
  tag {
    key                 = "prefix"
    value               = "idpxtra"
    propagate_at_launch = false
  }
  tag {
    key                 = "domain"
    value               = "${var.env_name}.${var.root_domain}"
    propagate_at_launch = false
  }
}

module "idpxtra_lifecycle_hooks" {
  source   = "github.com/18F/identity-terraform//asg_lifecycle_notifications?ref=8f0abe0e3708e2c1ef1c1653ae2b57b378bf8dbf"
  asg_name = aws_autoscaling_group.idpxtra.name
}

module "idpxtra_recycle" {
  source = "github.com/18F/identity-terraform//asg_recycle?ref=8f0abe0e3708e2c1ef1c1653ae2b57b378bf8dbf"

  # switch to count when that's a thing that we can do
  # https://github.com/hashicorp/terraform/issues/953
  enabled = var.asg_auto_recycle_enabled

  use_daily_business_hours_schedule = var.asg_recycle_business_hours

  asg_name                = aws_autoscaling_group.idpxtra.name
  normal_desired_capacity = aws_autoscaling_group.idpxtra.desired_capacity
}

resource "aws_autoscaling_policy" "idpxtra-cpu" {
  # Follow scale policies for normal IdP
  count = var.idp_cpu_autoscaling_enabled

  autoscaling_group_name = aws_autoscaling_group.idpxtra.name
  name                   = "cpu-scaling"

  # currently it takes about 15 minutes for instances to bootstrap
  estimated_instance_warmup = 900

  policy_type = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = var.idp_cpu_autoscaling_target

    disable_scale_in = var.idp_cpu_autoscaling_disable_scale_in == 1 ? true : false
  }
}

module "idpxtra_insufficent_instances_alerts" {
  source = "../modules/asg_insufficent_instances_alerts"

  asg_name = aws_autoscaling_group.idpxtra.name

  alarm_actions = local.high_priority_alarm_actions
}

module "idpxtra_unhealthy_instances_alerts" {
  source = "../modules/alb_unhealthy_instances_alerts"

  asg_name                = aws_autoscaling_group.idpxtra.name
  alb_arn_suffix          = aws_alb.idp.arn_suffix
  target_group_arn_suffix = aws_alb_target_group.idpxtra.arn_suffix

  alarm_actions = local.low_priority_alarm_actions
}
