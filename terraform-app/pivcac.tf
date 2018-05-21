module "pivcac_launch_config" {
  source = "../terraform-modules/bootstrap/"

  role = "pivcac"
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
resource "aws_launch_configuration" "pivcac" {
  name_prefix = "${var.env_name}.pivcac.${var.bootstrap_main_git_ref}."

  lifecycle {
    create_before_destroy = true
  }

  image_id = "${var.pivcac_ami_id}"
  instance_type = "${var.instance_type_pivcac}"
  security_groups = ["${aws_security_group.pivcac.id}"]

  user_data = "${module.pivcac_launch_config.rendered_cloudinit_config}"

  iam_instance_profile = "${aws_iam_instance_profile.pivcac.id}"
}

# For debugging cloud-init
#output "rendered_cloudinit_config" {
#  value = "${module.pivcac_launch_config.rendered_cloudinit_config}"
#}

resource "aws_iam_instance_profile" "pivcac" {
  name = "${var.env_name}_pivcac_instance_profile"
  role = "${aws_iam_role.pivcac.name}"
}

resource "aws_iam_role" "pivcac" {
  name = "${var.env_name}_pivcac_iam_role"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_from_vpc.json}"
}

resource "aws_iam_role_policy" "pivcac-secrets" {
  name = "${var.env_name}-pivcac-secrets"
  role = "${aws_iam_role.pivcac.id}"
  policy = "${data.aws_iam_policy_document.secrets_role_policy.json}"
}

resource "aws_autoscaling_group" "pivcac" {
    name = "${var.env_name}-pivcac"

    launch_configuration = "${aws_launch_configuration.pivcac.name}"

    min_size = 0
    max_size = "${var.pivcac_nodes * 2}"
    desired_capacity = "${var.pivcac_nodes}"

    # Don't create the ASG if we don't have an ELB.
    count = "${var.pivcac_service_enabled}"

    # Use the same subnet as the IDP.
    vpc_zone_identifier = [
      "${aws_subnet.idp1.id}",
      "${aws_subnet.idp2.id}"
    ]

    # TODO: Once these things start listening on 443, we should at least use that.
    health_check_type = "EC2"
    health_check_grace_period = 1200 # 20 minutes

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
        value = "asg-${var.env_name}-pivcac"
        propagate_at_launch = true
    }
    tag {
        key = "client"
        value = "${var.client}"
        propagate_at_launch = true
    }
    tag {
        key = "prefix"
        value = "pivcac"
        propagate_at_launch = true
    }
    tag {
        key = "domain"
        value = "${var.env_name}.${var.root_domain}"
        propagate_at_launch = true
    }
}

resource "aws_elb" "pivcac" {
  name = "${var.env_name}-pivcac"
  security_groups = ["${aws_security_group.web.id}"]
  subnets = ["${aws_subnet.alb1.id}", "${aws_subnet.alb2.id}"]

  access_logs = {
    bucket = "login-gov.elb-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
    bucket_prefix = "${var.env_name}/pivcac"
  }

  # TODO: Make a health check for this.
  listener {
    instance_port     = 443
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"
  }
}
