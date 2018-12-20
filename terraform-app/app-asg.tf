module "app_launch_config" {
  source = "../terraform-modules/bootstrap/"

  role = "app"
  env = "${var.env_name}"
  domain = "${var.root_domain}"

  chef_download_url = "${var.chef_download_url}"
  chef_download_sha256 = "${var.chef_download_sha256}"

  # identity-devops-private variables
  private_s3_ssh_key_url = "${local.bootstrap_private_s3_ssh_key_url}"
  private_git_clone_url = "${var.bootstrap_private_git_clone_url}"
  private_git_ref = "${var.bootstrap_private_git_ref}"

  # identity-devops variables
  main_s3_ssh_key_url = "${local.bootstrap_main_s3_ssh_key_url}"
  main_git_clone_url = "${var.bootstrap_main_git_clone_url}"
  main_git_ref_map = "${var.bootstrap_main_git_ref_map}"
  main_git_ref_default = "${local.bootstrap_main_git_ref_default}"

  # proxy variables
  proxy_server = "${var.proxy_server}"
  proxy_port = "${var.proxy_port}"
  no_proxy_hosts = "${var.no_proxy_hosts}"
  proxy_enabled_roles = "${var.proxy_enabled_roles}"
}

# TODO it would be nicer to have this in the module, but the
# aws_launch_configuration and aws_autoscaling_group must be in the same module
# due to https://github.com/terraform-providers/terraform-provider-aws/issues/681
# See discussion in ../terraform-modules/bootstrap/vestigial.tf.txt
resource "aws_launch_configuration" "app" {
  name_prefix = "${var.env_name}.app.${module.app_launch_config.main_git_ref}."

  lifecycle {
    create_before_destroy = true
  }

  image_id = "${lookup(var.ami_id_map, "app", local.account_default_ami_id)}"
  instance_type = "${var.instance_type_idp}"
  security_groups = ["${aws_security_group.app.id}"]

  user_data = "${module.app_launch_config.rendered_cloudinit_config}"

  iam_instance_profile = "${aws_iam_instance_profile.base-permissions.id}"
}

module "app_lifecycle_hooks" {
  source = "github.com/18F/identity-terraform//asg_lifecycle_notifications?ref=2c43bfd79a8a2377657bc8ed4764c3321c0f8e80"
  asg_name = "${element(concat(aws_autoscaling_group.app.*.name, list("")), 0)}"
  enabled = "${var.alb_enabled * var.apps_enabled}"
}

# For debugging cloud-init
#output "rendered_cloudinit_config" {
#  value = "${module.idp_launch_config.rendered_cloudinit_config}"
#}

resource "aws_autoscaling_group" "app" {
    name = "${var.env_name}-app"

    launch_configuration = "${aws_launch_configuration.app.name}"

    min_size = "${var.asg_app_min}"
    max_size = "${var.asg_app_max}"
    desired_capacity = "${var.asg_app_desired}"

    wait_for_capacity_timeout = 0

    # Don't create an IDP ASG if we don't have an ALB.
    # We can't refer to aws_alb_target_group.idp unless it exists.
    count = "${var.alb_enabled * var.apps_enabled}"

    target_group_arns = [
      "${aws_alb_target_group.app.arn}",
      "${aws_alb_target_group.app-ssl.arn}"
    ]

    vpc_zone_identifier = [
      "${aws_subnet.publicsubnet1.id}",
      "${aws_subnet.publicsubnet2.id}"
    ]

    # possible choices: EC2, ELB
    health_check_type = "ELB"

    # The grace period starts after lifecycle hooks are done and the instance
    # is InService. Having a grace period is dangerous because the ASG
    # considers instances in the grace period to be healthy.
    health_check_grace_period = 0

    termination_policies = ["OldestInstance"]

    # Because bootstrapping takes so long, we terminate manually in prod
    # More context on ASG deploys and safety:
    # https://github.com/18F/identity-devops-private/issues/337
    protect_from_scale_in = "${var.asg_prevent_auto_terminate}"

    tag {
        key = "Name"
        value = "asg-${var.env_name}-app"
        propagate_at_launch = true
    }
    tag {
        key = "prefix"
        value = "app"
        propagate_at_launch = true
    }
    tag {
        key = "domain"
        value = "${var.env_name}.${var.root_domain}"
        propagate_at_launch = true
    }
}

module "app_recycle" {
    source = "github.com/18F/identity-terraform//asg_recycle?ref=2c43bfd79a8a2377657bc8ed4764c3321c0f8e80"

    # switch to count when that's a thing that we can do
    # https://github.com/hashicorp/terraform/issues/953
    enabled = "${var.asg_auto_recycle_enabled * var.alb_enabled * var.apps_enabled}"

    use_daily_business_hours_schedule = "${var.asg_auto_recycle_use_business_schedule}"

    # This weird element() stuff is so we can refer to these attributes even
    # when the app autoscaling group has count=0. Reportedly this hack will not
    # be necessary in TF 0.12.
    asg_name = "${element(concat(aws_autoscaling_group.app.*.name, list("")), 0)}"
    normal_desired_capacity = "${element(concat(aws_autoscaling_group.app.*.desired_capacity, list("")), 0)}"
}
