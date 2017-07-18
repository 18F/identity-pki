module "jumphost_launch_config" {
    source = "../terraform-modules/bootstrap/"

    role = "jumphost"
    env = "${var.env_name}"
    domain = "login.gov"

    chef_download_url = "${var.chef_download_url}"
    chef_download_sha256 = "${var.chef_download_sha256}"

    s3_ssh_key_url = "${var.bootstrap_private_s3_ssh_key_url}"
    git_clone_url = "${var.bootstrap_private_git_clone_url}"
    git_ref = "${var.bootstrap_private_git_ref}"
}

# TODO it would be nicer to have this in the module, but the
# aws_launch_configuration and aws_autoscaling_group must be in the same module
# due to https://github.com/terraform-providers/terraform-provider-aws/issues/681
# See discussion in ../terraform-modules/bootstrap/vestigial.tf.txt
resource "aws_launch_configuration" "jumphost" {
    name_prefix = "${var.env_name}-jumphost-"

    lifecycle {
        create_before_destroy = true
    }

    image_id = "${var.jumphost_ami_id}"
    instance_type = "${var.instance_type_jumphost}"
    key_name = "${var.key_name}"
    security_groups = ["${aws_security_group.jumphost.id}"]

    user_data = "${module.jumphost_launch_config.rendered_cloudinit_config}"

    iam_instance_profile = "${aws_iam_instance_profile.jumphost.name}"
}

resource "aws_autoscaling_group" "jumphost" {
    name = "${var.env_name}-jumphost"

    launch_configuration = "${aws_launch_configuration.jumphost.name}"

    min_size = 0
    max_size = 4
    desired_capacity = "${var.asg_jumphost_desired}"

    # TODO: It would be nice to have a TCP load balancer for the jumphosts so
    # that clients can SSH through a jumphost without having to query the AWS
    # API to find jumphosts. This will also require either a common SSH host
    # key distributed by Citadel, or using SSH certificates issued by some SSH
    # certificate authority.
    # load_balancers = []

    # TODO: use multiple subnets so we actually get highly available jumphosts
    # in multiple AZs. Right now jumphosts will all be spun up in a single
    # subnet and AZ.
    # https://github.com/18F/identity-devops-private/issues/259
    vpc_zone_identifier = ["${aws_subnet.jumphost.id}"]

    # possible choices: EC2, ELB
    health_check_type = "EC2"

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
}

# TODO this should be in a module really
resource "aws_iam_role" "jumphost" {
  name = "${var.env_name}_jumphost"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_from_vpc.json}"
}
resource "aws_iam_role_policy" "jumphost" {
  name = "${var.env_name}_jumphost"
  role = "${aws_iam_role.jumphost.id}"
  policy = "${data.aws_iam_policy_document.secrets_role_policy.json}"
}
resource "aws_iam_instance_profile" "jumphost" {
  name = "${var.env_name}_jumphost"
  roles = ["${aws_iam_role.jumphost.name}"]
}


resource "aws_instance" "jumphost" {
  ami = "${var.jumphost_ami_id}"
  depends_on = ["aws_internet_gateway.default", "aws_route53_zone.internal","aws_instance.chef"]
  instance_type = "${var.instance_type_jumphost}"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.jumphost.id}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-jumphost-${var.env_name}"
  }

  connection {
    type = "ssh"
    user = "ubuntu"
    timeout = "1m"
  }

  vpc_security_group_ids = [ "${aws_security_group.jumphost.id}" ]

  provisioner "chef"  {
    attributes_json = <<-EOF
    {
      "set_fqdn": "jumphost.${var.env_name}.login.gov",
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
  depends_on = ["aws_instance.jumphost"]
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name = "jumphost.login.gov.internal"
  type = "A"
  ttl = "300"
  records = ["${aws_instance.jumphost.private_ip}"]
}

resource "aws_route53_record" "jumphost-reverse" {
  depends_on = ["aws_instance.jumphost"]
  zone_id = "${aws_route53_zone.internal-reverse.zone_id}"
  name = "${format("%s.%s.16.172.in-addr.arpa", element(split(".", aws_instance.jumphost.private_ip), 3), element(split(".", aws_instance.jumphost.private_ip), 2) )}"

  type = "PTR"
  ttl = "300"
  records = ["jumphost.login.gov.internal"]
}

resource "aws_eip" "jumphost" {
  instance = "${aws_instance.jumphost.id}"
  vpc      = true
}

resource "aws_route53_record" "a_jumphost" {
  name = "jumphost.${var.env_name}.login.gov"
  records = ["${aws_eip.jumphost.public_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${var.route53_id}"
}
