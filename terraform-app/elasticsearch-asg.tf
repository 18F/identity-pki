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

  user_data = "${module.elasticsearch_launch_config.rendered_cloudinit_config}"

  iam_instance_profile = "${aws_iam_instance_profile.idp.id}"
}

# For debugging cloud-init
#output "rendered_cloudinit_config" {
#  value = "${module.elasticsearch_launch_config.rendered_cloudinit_config}"
#}

resource "aws_autoscaling_group" "elasticsearch" {
    name = "${var.env_name}-elasticsearch"

    launch_configuration = "${aws_launch_configuration.elasticsearch.name}"

    min_size = 0
    max_size = 8
    desired_capacity = "${var.asg_elasticsearch_desired}"

    vpc_zone_identifier = ["${aws_subnet.elasticsearch.*.id}"]

    health_check_type = "ELB"
    health_check_grace_period = 1800 # 30 minutes

    termination_policies = ["OldestInstance"]

    load_balancers = ["${aws_elb.elasticsearch.id}"]

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
}
