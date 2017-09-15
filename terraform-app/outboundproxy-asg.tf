module "outboundproxy_launch_config" {
  source = "../terraform-modules/bootstrap/"

  role = "outboundproxy"
  env = "${var.env_name}"
  domain = "${var.root_domain}"

  chef_download_url = "${var.chef_download_url}"
  chef_download_sha256 = "${var.chef_download_sha256}"

  # identity-devops-private variables
  private_s3_ssh_key_url = "${var.bootstrap_private_s3_ssh_key_url}"
  private_git_clone_url = "${var.bootstrap_private_git_clone_url}"
  private_git_ref = "${var.bootstrap_private_git_ref}"

  # identity-devops variables
  main_s3_ssh_key_url = "${var.bootstrap_main_s3_ssh_key_url}"
  main_git_clone_url = "${var.bootstrap_main_git_clone_url}"
  main_git_ref = "${var.bootstrap_main_git_ref}"
}

# TODO it would be nicer to have this in the module, but the
# aws_launch_configuration and aws_autoscaling_group must be in the same module
# due to https://github.com/terraform-providers/terraform-provider-aws/issues/681
# See discussion in ../terraform-modules/bootstrap/vestigial.tf.txt
resource "aws_launch_configuration" "outboundproxy" {
  name_prefix = "${var.env_name}.outboundproxy.${var.bootstrap_main_git_ref}."

  lifecycle {
    create_before_destroy = true
  }

  image_id = "${var.outboundproxy_ami_id}"
  instance_type = "${var.instance_type_outboundproxy}"
  security_groups = ["${aws_security_group.obproxy.id}"] # TODO use a separate sg

  user_data = "${module.outboundproxy_launch_config.rendered_cloudinit_config}"

  iam_instance_profile = "${aws_iam_instance_profile.obproxy.id}"
}

# For debugging cloud-init
#output "rendered_cloudinit_config" {
#  value = "${module.outboundproxy_launch_config.rendered_cloudinit_config}"
#}

resource "aws_autoscaling_attachment" "asg_attachment_obproxy" {
  autoscaling_group_name = "${aws_autoscaling_group.outboundproxy.id}"
  elb                    = "${aws_elb.outboundproxy.id}"
}

resource "aws_autoscaling_group" "outboundproxy" {
    name = "${var.env_name}-outboundproxy"

    launch_configuration = "${aws_launch_configuration.outboundproxy.name}"

    min_size = 0
    max_size = 8
    desired_capacity = "${var.asg_outboundproxy_desired}"

    vpc_zone_identifier = [
      "${aws_subnet.outboundproxy1.id}",
      "${aws_subnet.outboundproxy2.id}"
    ]

    # possible choices: EC2, ELB
    health_check_type = "EC2"
    health_check_grace_period = 1800 # 30 minutes

    termination_policies = ["OldestInstance"]

    # We manually terminate instances in prod
    protect_from_scale_in = "${var.asg_prevent_auto_terminate}"

    tag {
        key = "Name"
        value = "asg-${var.env_name}-outboundproxy"
        propagate_at_launch = true
    }
    tag {
        key = "client"
        value = "${var.client}"
        propagate_at_launch = true
    }
    tag {
        key = "prefix"
        value = "outboundproxy"
        propagate_at_launch = true
    }
    tag {
        key = "domain"
        value = "${var.env_name}.${var.root_domain}"
        propagate_at_launch = true
    }
}

