module "elk_launch_config" {
  source = "../terraform-modules/bootstrap/"

  role = "elk"
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
resource "aws_launch_configuration" "elk" {
  name_prefix = "${var.env_name}.elk.${module.elk_launch_config.main_git_ref}."

  lifecycle {
    create_before_destroy = true
  }

  image_id = "${lookup(var.ami_id_map, "elk", local.account_default_ami_id)}"
  instance_type = "${var.instance_type_elk}"
  security_groups = ["${aws_security_group.elk.id}"]

  user_data = "${module.elk_launch_config.rendered_cloudinit_config}"

  iam_instance_profile = "${aws_iam_instance_profile.elk_instance_profile.id}"
}

module "elk_lifecycle_hooks" {
  source = "github.com/18F/identity-terraform//asg_lifecycle_notifications?ref=2c43bfd79a8a2377657bc8ed4764c3321c0f8e80"
  asg_name = "${aws_autoscaling_group.elk.name}"
}

# For debugging cloud-init
#output "rendered_cloudinit_config" {
#  value = "${module.elk_launch_config.rendered_cloudinit_config}"
#}

resource "aws_autoscaling_group" "elk" {
    name = "${var.env_name}-elk"

    launch_configuration = "${aws_launch_configuration.elk.name}"

    min_size = 0
    max_size = 8
    desired_capacity = "${var.asg_elk_desired}"

    wait_for_capacity_timeout = 0

    vpc_zone_identifier = ["${aws_subnet.elk.*.id}"]

    # https://github.com/18F/identity-devops-private/issues/631
    health_check_type = "EC2"
    health_check_grace_period = 0

    termination_policies = ["OldestInstance"]

    load_balancers = ["${aws_elb.elk.id}"]

    protect_from_scale_in = "${var.asg_prevent_auto_terminate}"

    tag {
        key = "Name"
        value = "asg-${var.env_name}-elk"
        propagate_at_launch = true
    }
    tag {
        key = "client"
        value = "${var.client}"
        propagate_at_launch = true
    }
    tag {
        key = "prefix"
        value = "elk"
        propagate_at_launch = true
    }
    tag {
        key = "domain"
        value = "${var.env_name}.${var.root_domain}"
        propagate_at_launch = true
    }
    tag {
        key = "identity-devops-gitref"
        value = "${module.elk_launch_config.main_git_ref}"
        propagate_at_launch = true
    }
    tag {
        key = "identity-devops-private-gitref"
        value = "${module.elk_launch_config.private_git_ref}"
        propagate_at_launch = true
    }
}
