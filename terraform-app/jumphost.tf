module "jumphost_launch_config" {
    source = "../terraform-modules/bootstrap/"

    role = "jumphost"
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
resource "aws_launch_configuration" "jumphost" {
    name_prefix = "${var.env_name}.jumphost.${var.bootstrap_main_git_ref}."

    lifecycle {
        create_before_destroy = true
    }

    image_id = "${var.jumphost_ami_id}"
    instance_type = "${var.instance_type_jumphost}"
    security_groups = ["${aws_security_group.jumphost.id}"]

    user_data = "${module.jumphost_launch_config.rendered_cloudinit_config}"

    iam_instance_profile = "${aws_iam_instance_profile.base-permissions.name}"
}

# For debugging cloud-init
#output "rendered_cloudinit_config" {
#    value = "${module.jumphost_launch_config.rendered_cloudinit_config}"
#}

resource "aws_autoscaling_group" "jumphost" {
    name = "${var.env_name}-jumphost"

    launch_configuration = "${aws_launch_configuration.jumphost.name}"

    min_size = 0
    max_size = 4 # TODO count subnets or Region's AZ width
    desired_capacity = "${var.asg_jumphost_desired}"
    wait_for_capacity_timeout = 0	# 0 == ignore

    # TODO use certificates instead of host keys
    # see http://man.openbsd.org/ssh-keygen#CERTIFICATES and Issue #621
    load_balancers = ["${aws_elb.jumphost.name}"]

    # https://github.com/18F/identity-devops-private/issues/259
    vpc_zone_identifier = [
      "${aws_subnet.jumphost1.id}",
      "${aws_subnet.jumphost2.id}"
    ]

    health_check_type = "ELB"
    health_check_grace_period = 1200    # flavored AMI can omit (default=300)
    termination_policies = ["OldestInstance"]

    tag {
        key = "Name"
        value = "asg-${var.env_name}-jumphost"
        propagate_at_launch = true
    }
    tag {
        key = "client"
        value = "${var.client}"
        propagate_at_launch = true
    }
    tag {
        key = "prefix"
        value = "jumphost"
        propagate_at_launch = true
    }
    tag {
        key = "domain"
        value = "${var.env_name}.${var.root_domain}"
        propagate_at_launch = true
    }

    # We manually terminate instances in prod
    protect_from_scale_in = "${var.asg_prevent_auto_terminate}"
}

# legacy
resource "aws_instance" "jumphost" {
  count = "${var.non_asg_jumphost_enabled}"
  ami = "${var.jumphost_ami_id}"
  depends_on = ["aws_internet_gateway.default", "aws_route53_zone.internal", "aws_instance.chef"]
  instance_type = "${var.instance_type_jumphost}"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.jumphost.id}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-jumphost-${var.env_name}"
    prefix = "jumphost"
    domain = "${var.env_name}.${var.root_domain}"
  }

  lifecycle {
    ignore_changes = ["ami", "instance_type"]
  }

  connection {
    type = "ssh"
    # TF BUG! can't parse variables for 'user' (eg. "${var.jumphost_ami_userid}")
    user = "ubuntu"
  }

  vpc_security_group_ids = [ "${aws_security_group.jumphost.id}" ]

  iam_instance_profile = "${aws_iam_instance_profile.base-permissions.name}"

  # WARNING CIS approved image prohibits executable /tmp
  # change the AMI to a less restrictive one: ami-bca32edc

  provisioner "chef"  {
    attributes_json = <<-EOF
    {
      "set_fqdn": "jumphost.${var.env_name}.${var.root_domain}",
      "login_dot_gov": {
        "live_certs": "${var.live_certs}"
      }
    }
    EOF
    environment = "${var.env_name}"
    run_list = [
      "role[base]",
      "recipe[identity-jumphost]"
    ]
    node_name = "jumphost.${var.env_name}"
    secret_key = "${file("${var.chef_databag_key_path}")}"
    server_url = "${var.chef_url}"
    recreate_client = true
    user_name = "${var.chef_id}"
    user_key = "${file("${var.chef_id_key_path}")}"
    version = "${var.chef_version}"
    fetch_chef_certificates = true
  }
}

resource "aws_route53_record" "jumphost" {
  count   = "${var.non_asg_jumphost_enabled}"
  depends_on = ["aws_instance.jumphost"]
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name    = "jumphost.login.gov.internal"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.jumphost.*.private_ip}"]
}

resource "aws_route53_record" "jumphost-reverse" {
  count = "${var.non_asg_jumphost_enabled}"
  depends_on = ["aws_instance.jumphost"]
  zone_id = "${aws_route53_zone.internal-reverse.zone_id}"
  name = "${format("%s.%s.%s.%s.in-addr.arpa",
            element(split(".", element(aws_instance.jumphost.*.private_ip, count.index)), 3),
            element(split(".", element(aws_instance.jumphost.*.private_ip, count.index)), 2),
            element(split(".", element(aws_instance.jumphost.*.private_ip, count.index)), 1),
            element(split(".", element(aws_instance.jumphost.*.private_ip, count.index)), 0)
        )}"
  type = "PTR"
  ttl = "300"
  records = ["jumphost.login.gov.internal"]
}

resource "aws_eip" "jumphost" {
  count    = "${var.non_asg_jumphost_enabled}"
  instance = "${element(aws_instance.jumphost.*.id, count.index)}"
  vpc      = true
}

resource "aws_route53_record" "a_jumphost" {
  count     = "${var.non_asg_jumphost_enabled}"
  zone_id   = "${aws_route53_zone.internal.zone_id}"
  name      = "jumphost.${var.env_name}.${var.root_domain}"
  type      = "A"
  ttl       = "300"
  records   = ["${aws_eip.jumphost.*.public_ip}"]
}
