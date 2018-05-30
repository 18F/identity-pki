module "elasticsearch_launch_config" {
  source = "../terraform-modules/bootstrap/"

  role = "elasticsearch"
  env = "${var.env_name}"
  domain = "${var.root_domain}"

  chef_download_url = "${var.chef_download_url}"
  chef_download_sha256 = "${var.chef_download_sha256}"

  # identity-devops-private variables
  private_s3_ssh_key_url = "${var.bootstrap_private_s3_ssh_key_url}"
  private_git_clone_url = "${var.bootstrap_private_git_clone_url}"
  private_git_ref = "${var.bootstrap_private_git_ref_elasticsearch}"

  # identity-devops variables
  main_s3_ssh_key_url = "${var.bootstrap_main_s3_ssh_key_url}"
  main_git_clone_url = "${var.bootstrap_main_git_clone_url}"
  main_git_ref = "${var.bootstrap_main_git_ref_elasticsearch}"
}

# TODO it would be nicer to have this in the module, but the
# aws_launch_configuration and aws_autoscaling_group must be in the same module
# due to https://github.com/terraform-providers/terraform-provider-aws/issues/681
# See discussion in ../terraform-modules/bootstrap/vestigial.tf.txt
resource "aws_launch_configuration" "elasticsearch" {
  name_prefix = "${var.env_name}.elasticsearch.${var.bootstrap_main_git_ref_elasticsearch}."

  lifecycle {
    create_before_destroy = true
  }

  image_id = "${var.elasticsearch_ami_id}"
  instance_type = "${var.instance_type_es}"
  security_groups = ["${aws_security_group.elk.id}"]

  # We will add this to the var VG
  ebs_block_device {
    device_name = "/dev/sdg"
    volume_size = "${var.elasticsearch_volume_size}"
    volume_type = "gp2"
    encrypted = true
    delete_on_termination = true
  }

  user_data = "${module.elasticsearch_launch_config.rendered_cloudinit_config}"

  iam_instance_profile = "${aws_iam_instance_profile.idp.id}"
}

module "elasticsearch_lifecycle_hooks" {
  source = "github.com/18F/identity-terraform//asg_lifecycle_notifications?ref=e491567564505dfa2f944da5c065cc2bfa4f800e"
  asg_name = "${aws_autoscaling_group.elasticsearch.name}"
}

# For debugging cloud-init
#output "rendered_cloudinit_config" {
#  value = "${module.elasticsearch_launch_config.rendered_cloudinit_config}"
#}

resource "aws_autoscaling_group" "elasticsearch" {
    name = "${var.env_name}-elasticsearch"

    launch_configuration = "${aws_launch_configuration.elasticsearch.name}"

    min_size = 0
    max_size = 32
    desired_capacity = "${var.asg_elasticsearch_desired}"

    vpc_zone_identifier = ["${aws_subnet.elasticsearch.*.id}"]

    # https://github.com/18F/identity-devops-private/issues/631
    health_check_type = "EC2"
    health_check_grace_period = 0

    termination_policies = ["OldestInstance"]

    target_group_arns = ["${aws_lb_target_group.elasticsearch.arn}"]

    # Because these nodes have persistent data, we terminate manually in prod.
    protect_from_scale_in = "${var.asg_prevent_auto_terminate}"

    tag {
        key = "Name"
        value = "asg-${var.env_name}-elasticsearch"
        propagate_at_launch = true
    }
    tag {
        key = "client"
        value = "${var.client}"
        propagate_at_launch = true
    }
    tag {
        key = "prefix"
        value = "elasticsearch"
        propagate_at_launch = true
    }
    tag {
        key = "domain"
        value = "${var.env_name}.${var.root_domain}"
        propagate_at_launch = true
    }
    tag {
        key = "identity-devops-gitref"
        value = "${var.bootstrap_main_git_ref_elasticsearch}"
        propagate_at_launch = true
    }
    tag {
        key = "identity-devops-private-gitref"
        value = "${var.bootstrap_private_git_ref_elasticsearch}"
        propagate_at_launch = true
    }

    # elasticsearch instances are stateful, shouldn't be recycled willy nilly
    tag {
        key = "stateful"
        value = "true"
        propagate_at_launch = true
    }
}
