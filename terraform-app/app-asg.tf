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
  private_git_ref = "${local.bootstrap_private_git_ref}"

  # identity-devops variables
  main_s3_ssh_key_url = "${local.bootstrap_main_s3_ssh_key_url}"
  main_git_clone_url = "${var.bootstrap_main_git_clone_url}"
  main_git_ref = "${local.bootstrap_main_git_ref}"
}

# TODO it would be nicer to have this in the module, but the
# aws_launch_configuration and aws_autoscaling_group must be in the same module
# due to https://github.com/terraform-providers/terraform-provider-aws/issues/681
# See discussion in ../terraform-modules/bootstrap/vestigial.tf.txt
resource "aws_launch_configuration" "app" {
  name_prefix = "${var.env_name}.app.${local.bootstrap_main_git_ref}."

  lifecycle {
    create_before_destroy = true
  }

  image_id = "${lookup(var.ami_id_map, "app", var.default_ami_id)}"
  instance_type = "${var.instance_type_idp}"
  security_groups = ["${aws_security_group.app.id}"]

  user_data = "${module.app_launch_config.rendered_cloudinit_config}"

  iam_instance_profile = "${aws_iam_instance_profile.base-permissions.id}"
}

module "app_lifecycle_hooks" {
  source = "github.com/18F/identity-terraform//asg_lifecycle_notifications?ref=e491567564505dfa2f944da5c065cc2bfa4f800e"
  asg_name = "${var.env_name}-app"
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

    # Don't create an IDP ASG if we don't have an ALB.
    # We can't refer to aws_alb_target_group.idp unless it exists.
    count = "${var.alb_enabled * var.apps_enabled}"

    target_group_arns = [
      "${aws_alb_target_group.app.arn}",
      "${aws_alb_target_group.app-ssl.arn}"
    ]

    # TODO: make it highly available
    vpc_zone_identifier = [
      "${aws_subnet.app.id}"
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

# TODO uncomment this when the app ASG always exists
# We can't refer to variables like aws_autoscaling_group.app.name unless the
# resource exists, and we can't use count on modules because terraform doesn't
# support it.
# https://github.com/hashicorp/terraform/issues/953
# https://github.com/hashicorp/terraform/issues/11566
#
#module "app_recycle" {
#    source = "../terraform-modules/asg_recycle/"
#
#    enabled = "${var.asg_auto_6h_recycle * var.alb_enabled * var.apps_enabled}"
#
#    asg_name = "${aws_autoscaling_group.app.name}"
#    normal_desired_capacity = "${aws_autoscaling_group.app.desired_capacity}"
#
#    # TODO once we're on TF 0.10 remove these
#    min_size = "${aws_autoscaling_group.app.min_size}"
#    max_size = "${aws_autoscaling_group.app.max_size}"
#}
