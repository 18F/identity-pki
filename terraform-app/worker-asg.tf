module "worker_launch_config" {
  source = "../terraform-modules/bootstrap/"

  role = "worker"
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
resource "aws_launch_configuration" "worker" {
  name_prefix = "${var.env_name}.worker.${module.worker_launch_config.main_git_ref}."

  lifecycle {
    create_before_destroy = true
  }

  image_id = "${lookup(var.ami_id_map, "worker", var.default_ami_id)}"
  instance_type = "${var.instance_type_worker}"
  security_groups = ["${aws_security_group.idp.id}"] # TODO use a separate sg

  user_data = "${module.worker_launch_config.rendered_cloudinit_config}"

  iam_instance_profile = "${aws_iam_instance_profile.idp.id}"
}

module "worker_lifecycle_hooks" {
  source = "github.com/18F/identity-terraform//asg_lifecycle_notifications?ref=62385b497f5b8dba2478be5759d53c1fb2353185"
  asg_name = "${aws_autoscaling_group.worker.name}"
}

# For debugging cloud-init
#output "rendered_cloudinit_config" {
#  value = "${module.worker_launch_config.rendered_cloudinit_config}"
#}

resource "aws_autoscaling_group" "worker" {
    name = "${var.env_name}-worker"

    launch_configuration = "${aws_launch_configuration.worker.name}"

    min_size = "${var.asg_worker_min}"
    max_size = "${var.asg_worker_max}"
    desired_capacity = "${var.asg_worker_desired}"

    wait_for_capacity_timeout = 0

    # Don't create an IDP ASG if we don't have an ALB.
    # We can't refer to aws_alb_target_group.idp unless it exists.
    count = "${var.alb_enabled}"

    vpc_zone_identifier = [
      "${aws_subnet.idp1.id}",
      "${aws_subnet.idp2.id}"
    ]

    # TODO: We should potentially create an ELB/ALB for health checks. With the
    # EC2 health checks, the ASG can't tell if the instance is actually
    # working, only that the bare instance appears to be turned on.
    # target_group_arns = []
    # possible choices: EC2, ELB
    health_check_type = "EC2"
    health_check_grace_period = 0

    termination_policies = ["OldestInstance"]

    # Because bootstrapping takes so long, we terminate manually in prod
    # We also would want to switch to an ELB health check before allowing AWS
    # to automatically terminate instances. Right now the ASG can't tell if
    # instance bootstrapping completed successfully.
    # https://github.com/18F/identity-devops-private/issues/337
    protect_from_scale_in = "${var.asg_prevent_auto_terminate}"

    enabled_metrics = "${var.asg_enabled_metrics}"

    tag {
        key = "Name"
        value = "asg-${var.env_name}-worker"
        propagate_at_launch = true
    }
    tag {
        key = "client"
        value = "${var.client}"
        propagate_at_launch = true
    }
    tag {
        key = "prefix"
        value = "worker"
        propagate_at_launch = true
    }
    tag {
        key = "domain"
        value = "${var.env_name}.${var.root_domain}"
        propagate_at_launch = true
    }
}

module "worker_recycle" {
    source = "../terraform-modules/asg_recycle/"

    enabled = "${var.asg_auto_6h_recycle}"

    asg_name = "${aws_autoscaling_group.worker.name}"
    normal_desired_capacity = "${aws_autoscaling_group.worker.desired_capacity}"

    # TODO once we're on TF 0.10 remove these
    min_size = "${aws_autoscaling_group.worker.min_size}"
    max_size = "${aws_autoscaling_group.worker.max_size}"
}
