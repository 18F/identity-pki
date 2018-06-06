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

# TODO it would be nicer to have this in the module, but the
# aws_launch_configuration and aws_autoscaling_group must be in the same module
# due to https://github.com/terraform-providers/terraform-provider-aws/issues/681
# See discussion in ../terraform-modules/bootstrap/vestigial.tf.txt
resource "aws_launch_configuration" "outboundproxy" {
  name_prefix = "${var.env_name}.outboundproxy.${var.bootstrap_main_git_ref}."

  lifecycle {
    create_before_destroy = true
  }

  image_id = "${lookup(var.ami_id_map, "outboundproxy", var.default_ami_id)}"
  instance_type = "${var.instance_type_outboundproxy}"
  security_groups = ["${aws_security_group.obproxy.id}"] 

  user_data = "${module.outboundproxy_launch_config.rendered_cloudinit_config}"

  iam_instance_profile = "${aws_iam_instance_profile.obproxy.id}"
}

# For debugging cloud-init
#output "rendered_cloudinit_config" {
#  value = "${module.outboundproxy_launch_config.rendered_cloudinit_config}"
#}

# ELB here
resource "aws_elb" "outboundproxy" {
  name                = "${var.name}-outboundproxy-elb-${var.env_name}"
  security_groups     = ["${aws_security_group.obproxy.id}"]
  subnets             = ["${aws_subnet.publicsubnet1.id}", "${aws_subnet.publicsubnet2.id}", "${aws_subnet.publicsubnet3.id}"]
  connection_draining = true
  internal            = true
  cross_zone_load_balancing   = true

  access_logs {
    bucket        = "login-gov.elb-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
    bucket_prefix = "${var.env_name}/outboundproxy"
    interval      = 5
  }

  listener {
    instance_port     = "3128"
    instance_protocol = "TCP"
    lb_port           = "3128"
    lb_protocol       = "TCP"
  }

  health_check {
    target              = "TCP:3128"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
  }
}

resource "aws_route53_record" "obproxy" {
  depends_on = ["aws_elb.outboundproxy"]
  zone_id    = "${aws_route53_zone.internal.zone_id}"
  name       = "obproxy.login.gov.internal"
  type       = "CNAME"
  ttl        = "300"
  records    = ["${aws_elb.outboundproxy.dns_name}"]
}

resource "aws_autoscaling_group" "outboundproxy" {
  name = "${var.env_name}-outboundproxy"
  launch_configuration = "${aws_launch_configuration.outboundproxy.name}"

  min_size         = 1
  max_size         = 8
  desired_capacity = "${var.asg_outboundproxy_desired}"

  lifecycle {
    create_before_destroy = true
  }

  vpc_zone_identifier = [
    "${aws_subnet.publicsubnet1.id}",
    "${aws_subnet.publicsubnet2.id}",
    "${aws_subnet.publicsubnet3.id}",
  ]

  load_balancers = ["${aws_elb.outboundproxy.id}"]

  # possible choices: EC2, ELB
  health_check_type         = "EC2"
  health_check_grace_period = 900   # 15 minutes

  termination_policies = ["OldestInstance"]

  # We manually terminate instances in prod
  protect_from_scale_in = "${var.asg_prevent_auto_terminate}"

  tag {
    key                 = "Name"
    value               = "asg-${var.env_name}-outboundproxy"
    propagate_at_launch = true
  }

  tag {
    key                 = "prefix"
    value               = "outboundproxy"
    propagate_at_launch = true
  }

  tag {
    key                 = "domain"
    value               = "${var.env_name}.${var.root_domain}"
    propagate_at_launch = true
  }
}
