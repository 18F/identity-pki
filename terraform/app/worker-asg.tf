module "worker_user_data" {
  source = "../modules/bootstrap/"

  role                   = "worker"
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

  # proxy settings
  proxy_server        = var.proxy_server
  proxy_port          = var.proxy_port
  no_proxy_hosts      = var.no_proxy_hosts
  proxy_enabled_roles = var.proxy_enabled_roles
}

resource "aws_iam_instance_profile" "worker" {
  name = "${var.env_name}_worker_instance_profile"
  role = module.application_iam_roles.worker_iam_role_name
}

module "worker_launch_template" {
  source = "github.com/18F/identity-terraform//launch_template?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/launch_template"
  role           = "worker"
  env            = var.env_name
  root_domain    = var.root_domain
  ami_id_map     = var.ami_id_map_uw2
  default_ami_id = local.account_rails_ami_id

  instance_type             = var.instance_type_worker
  iam_instance_profile_name = aws_iam_instance_profile.worker.name
  security_group_ids        = [aws_security_group.worker.id, module.network_uw2.base_id]
  user_data                 = module.worker_user_data.rendered_cloudinit_config

  use_spot_instances = var.use_spot_instances == 1 ? (
    length(var.worker_mixed_instance_config) == 0 ? 1 : 0
  ) : 0

  template_tags = {
    main_git_ref = module.worker_user_data.main_git_ref
  }
}

module "worker_lifecycle_hooks" {
  source = "github.com/18F/identity-terraform//asg_lifecycle_notifications?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/asg_lifecycle_notifications"
  asg_name = aws_autoscaling_group.worker.name
}

module "worker_recycle" {
  source = "github.com/18F/identity-terraform//asg_recycle?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/asg_recycle"

  asg_name       = aws_autoscaling_group.worker.name
  normal_min     = var.asg_worker_min
  normal_max     = var.asg_worker_max
  normal_desired = var.asg_worker_desired
  scale_schedule = var.autoscaling_schedule_name
  time_zone      = var.autoscaling_time_zone
}

resource "aws_autoscaling_group" "worker" {
  name = "${var.env_name}-worker"

  # use launch_template if var.idp_mixed_instance_config is not specified;
  # otherwise will throw InvalidQueryParameter error if var.use_spot_instances == 1
  dynamic "launch_template" {
    for_each = length(var.worker_mixed_instance_config) == 0 ? [1] : []

    content {
      id      = module.worker_launch_template.template_id
      version = "$Latest"
    }
  }

  dynamic "mixed_instances_policy" {
    for_each = length(var.worker_mixed_instance_config) == 0 ? [] : [1]

    content {
      instances_distribution {
        on_demand_base_capacity = (
          var.use_spot_instances == 1 ? 0 : var.asg_worker_max
        )
        on_demand_percentage_above_base_capacity = (
          var.use_spot_instances != 1 ? 100 : 0
        )
        spot_allocation_strategy = "capacity-optimized"
      }

      launch_template {
        launch_template_specification {
          launch_template_id = module.worker_launch_template.template_id
          version            = "$Latest"
        }

        # at least one override, containing the instance type within
        # the launch template, must be present
        override {
          instance_type     = var.instance_type_worker
          weighted_capacity = var.worker_default_weight
        }

        dynamic "override" {
          for_each = var.worker_mixed_instance_config

          content {
            instance_type     = override.value.instance_type
            weighted_capacity = override.value.weighted_capacity
          }
        }
      }
    }
  }

  min_size         = var.asg_worker_min
  max_size         = var.asg_worker_max
  desired_capacity = var.asg_worker_desired

  wait_for_capacity_timeout = 0

  lifecycle {
    create_before_destroy = true
  }

  target_group_arns = [
    aws_alb_target_group.worker.arn,
    aws_alb_target_group.worker_ssl.arn,
  ]

  vpc_zone_identifier = [for subnet in module.network_uw2.app_subnet : subnet.id]

  health_check_type         = "ELB"
  health_check_grace_period = 1

  termination_policies = ["OldestInstance"]

  # We manually terminate instances in prod
  protect_from_scale_in = var.asg_prevent_auto_terminate == 1 ? true : false

  enabled_metrics = var.asg_enabled_metrics

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
  tag {
    key                 = "fisma"
    value               = var.fisma_tag
    propagate_at_launch = true
  }

  depends_on = [
    module.outboundproxy_uw2.proxy_asg_name,
    module.migration_usw2.migration_asg_name,
    aws_autoscaling_group.idp,
    aws_cloudwatch_log_group.nginx_access_log
  ]
}

resource "aws_autoscaling_policy" "worker" {
  count                     = var.worker_cpu_autoscaling_enabled
  name                      = "${var.env_name}-worker-cpu"
  autoscaling_group_name    = aws_autoscaling_group.worker.name
  estimated_instance_warmup = 900

  policy_type = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.worker_cpu_autoscaling_target
  }
}
