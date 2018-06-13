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

  # proxy variables
  proxy_server = ""
  proxy_port = ""
  no_proxy_hosts = ""
}

resource "aws_iam_role" "obproxy" {
  name               = "${var.env_name}_obproxy_iam_role"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_from_vpc.json}"
}

resource "aws_iam_instance_profile" "obproxy" {
  name = "${var.env_name}_obproxy_instance_profile"
  role = "${aws_iam_role.obproxy.name}"
}

resource "aws_iam_role_policy" "obproxy-secrets" {
  name   = "${var.env_name}-obproxy-secrets"
  role   = "${aws_iam_role.obproxy.id}"
  policy = "${data.aws_iam_policy_document.secrets_role_policy.json}"
}

resource "aws_iam_role_policy" "obproxy-certificates" {
  name   = "${var.env_name}-obproxy-certificates"
  role   = "${aws_iam_role.obproxy.id}"
  policy = "${data.aws_iam_policy_document.certificates_role_policy.json}"
}

resource "aws_iam_role_policy" "obproxy-describe_instances" {
  name   = "${var.env_name}-obproxy-describe_instances"
  role   = "${aws_iam_role.obproxy.id}"
  policy = "${data.aws_iam_policy_document.describe_instances_role_policy.json}"
}

resource "aws_iam_role_policy" "obproxy-cloudwatch-logs" {
  name = "${var.env_name}-idp-cloudwatch-logs"
  role = "${aws_iam_role.obproxy.id}"
  policy = "${data.aws_iam_policy_document.cloudwatch-logs.json}"
}

resource "aws_iam_role_policy" "obproxy-auto-eip" {
  name = "${var.env_name}-obproxy-auto-eip"
  role = "${aws_iam_role.obproxy.id}"
  policy = "${data.aws_iam_policy_document.auto_eip_policy.json}"
}

resource "aws_launch_template" "outboundproxy" {
  name = "${var.name}-outboundproxy-template-${var.env_name}"

  iam_instance_profile {
    name = "${aws_iam_instance_profile.obproxy.name}"
  }

  image_id = "${lookup(var.ami_id_map, "outboundproxy", var.default_ami_id)}"

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = "${var.instance_type_outboundproxy}"

  user_data = "${module.outboundproxy_launch_config.rendered_cloudinit_config}"

  monitoring {
    enabled = true
  }

  vpc_security_group_ids = ["${aws_security_group.obproxy.id}"]

  tag_specifications {
    resource_type = "instance"
    tags {
      Name = "asg-${var.env_name}-outboundproxy",
      prefix = "outboundproxy",
      domain = "${var.env_name}.${var.root_domain}"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags {
      Name = "asg-${var.env_name}-outboundproxy",
      prefix = "outboundproxy",
      domain = "${var.env_name}.${var.root_domain}"
    }
  }
}

# For debugging cloud-init
#output "rendered_cloudinit_config" {
#  value = "${module.outboundproxy_launch_config.rendered_cloudinit_config}"
#}

module "obproxy_lifecycle_hooks" {
  source = "github.com/18F/identity-terraform//asg_lifecycle_notifications?ref=e491567564505dfa2f944da5c065cc2bfa4f800e"
  asg_name = "${aws_autoscaling_group.outboundproxy.name}"
}

resource "aws_route53_record" "obproxy" {
  depends_on = ["aws_lb.outboundproxy"]
  zone_id    = "${aws_route53_zone.internal.zone_id}"
  name       = "obproxy.login.gov.internal"
  type       = "CNAME"
  ttl        = "300"
  records    = ["${aws_lb.outboundproxy.dns_name}"]
}

resource "aws_autoscaling_group" "outboundproxy" {
  depends_on = ["aws_lb.outboundproxy"]
  name = "${var.env_name}-outboundproxy"

  min_size         = "${var.asg_outboundproxy_min}"
  max_size         = "${var.asg_outboundproxy_max}"
  desired_capacity = "${var.asg_outboundproxy_desired}"

  lifecycle {
    create_before_destroy = true
  }

  vpc_zone_identifier = [
    "${aws_subnet.publicsubnet1.id}",
    "${aws_subnet.publicsubnet2.id}",
    "${aws_subnet.publicsubnet3.id}",
  ]

  target_group_arns = [
    "${aws_lb_target_group.outboundproxy.arn}"
  ]

  health_check_type         = "EC2"
  health_check_grace_period = 0

  termination_policies = ["OldestInstance"]

  # We manually terminate instances in prod
  protect_from_scale_in = "${var.asg_prevent_auto_terminate}"

  launch_template = {
    id = "${aws_launch_template.outboundproxy.id}"
    version = "$$Latest"
  }

  tag {
    key = "Name"
    value = "asg-${var.env_name}-outboundproxy"
    propagate_at_launch = false
  }
  tag {
    key = "prefix"
    value = "outboundproxy"
    propagate_at_launch = false
  }
  tag {
    key = "domain"
    value = "${var.env_name}.${var.root_domain}"
    propagate_at_launch = false
  }
}
