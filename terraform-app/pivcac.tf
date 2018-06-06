module "pivcac_launch_config" {
  source = "../terraform-modules/bootstrap/"

  role = "pivcac"
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
resource "aws_launch_configuration" "pivcac" {
  name_prefix = "${var.env_name}.pivcac.${local.bootstrap_main_git_ref}."

  lifecycle {
    create_before_destroy = true
  }

  image_id = "${lookup(var.ami_id_map, "pivcac", var.default_ami_id)}"
  instance_type = "${var.instance_type_pivcac}"
  security_groups = ["${aws_security_group.pivcac.id}"]

  user_data = "${module.pivcac_launch_config.rendered_cloudinit_config}"

  iam_instance_profile = "${aws_iam_instance_profile.pivcac.id}"
}

module "pivcac_lifecycle_hooks" {
  source = "github.com/18F/identity-terraform//asg_lifecycle_notifications?ref=e491567564505dfa2f944da5c065cc2bfa4f800e"
  asg_name = "${var.env_name}-pivcac"
  enabled = "${var.pivcac_service_enabled}"
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

resource "aws_iam_role_policy" "pivcac-certificates" {
  name = "${var.env_name}-pivcac-certificates"
  role = "${aws_iam_role.pivcac.id}"
  policy = "${data.aws_iam_policy_document.certificates_role_policy.json}"
}

resource "aws_iam_role_policy" "pivcac-describe_instances" {
  name = "${var.env_name}-pivcac-describe_instances"
  role = "${aws_iam_role.pivcac.id}"
  policy = "${data.aws_iam_policy_document.describe_instances_role_policy.json}"
}

resource "aws_iam_role_policy" "pivcac-cloudwatch-logs" {
  name = "${var.env_name}-pivcac-cloudwatch-logs"
  role = "${aws_iam_role.pivcac.id}"
  policy = "${data.aws_iam_policy_document.cloudwatch-logs.json}"
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

    load_balancers = ["${aws_elb.pivcac.id}"]

    health_check_type = "ELB"
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
  count = "${var.pivcac_service_enabled}"

  access_logs = {
    bucket = "login-gov.elb-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
    bucket_prefix = "${var.env_name}/pivcac"
  }

  listener {
    instance_port     = 443
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"
  }

  health_check {
    target = "HTTPS:443/health_check"
    healthy_threshold = 3
    unhealthy_threshold = 3
    interval = 10
    timeout = 3
  }
}

resource "aws_s3_bucket" "pivcac_cert_bucket" {
  bucket = "login-gov-pivcac-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"

  tags {
    Name = "login-gov-pivcac-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"
  }
  policy = "${data.aws_iam_policy_document.pivcac_bucket_policy.json}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

data "aws_iam_policy_document" "pivcac_bucket_policy" {
  # allow pivcac hosts to read and write their SSL certs
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    principals = {
      type ="AWS"
      identifiers = [
        "${aws_iam_role.pivcac.arn}"
      ]
    }

    resources = [
      "arn:aws:s3:::login-gov-pivcac-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}",
      "arn:aws:s3:::login-gov-pivcac-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}/*"
    ]
  }
}
