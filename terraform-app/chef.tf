data "template_file" "install-chef-server" {
  template = "${file("install-chef-server.sh.tpl")}"
  vars {
    chef_version = "${var.chef_version}"
    chef_pw = "${var.rds_password}"
    env_name = "${var.env_name}"
    region = "${var.region}"
    chef_repo_gitref = "${var.chef_repo_gitref}"
  }
}

resource "aws_iam_role" "chef" {
  name = "${var.env_name}_chef"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_from_vpc.json}"
}

resource "aws_iam_instance_profile" "chef" {
  name = "${var.env_name}_chef"
  roles = ["${aws_iam_role.chef.name}"]
}

resource "aws_instance" "chef" {
  ami = "${var.default_ami_id}"
  depends_on = ["aws_internet_gateway.default", "aws_route53_zone.internal"]
  instance_type = "${var.instance_type_chef}"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.admin.id}"
  iam_instance_profile = "${aws_iam_instance_profile.chef.id}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-chef-${var.env_name}"
  }

  connection {
    type = "ssh"
    user = "ubuntu"
  }

  vpc_security_group_ids = [ "${aws_security_group.chef.id}" ]

  provisioner "file" {
    content = "${data.template_file.install-chef-server.rendered}"
    destination = "./install-chef-server.sh"
  }
  provisioner "file" {
    source = "${var.git_deploy_key_path}"
    destination = "./id_rsa_deploy"
  }
  provisioner "file" {
    source = "knife.rb"
    destination = "./knife.rb"
  }
  # This is dumb because we cannot exec stuff in /tmp, which remote-exec needs to work.
  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no ubuntu@${aws_instance.chef.public_ip} sudo sh ./install-chef-server.sh"
  }

  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no ubuntu@${aws_instance.chef.public_ip} sudo chef-server-ctl user-create ${var.chef_id} ${var.chef_info} > ~/.chef/${var.chef_id}-${var.env_name}.pem"
  }
  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no ubuntu@${aws_instance.chef.public_ip} sudo chef-server-ctl org-user-add login-dev ${var.chef_id} --admin"
  }
  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no ubuntu@${aws_instance.chef.public_ip} sudo cat /root/login-dev-validator.pem > ~/.chef/${var.env_name}-login-dev-validator.pem"
  }

  provisioner "chef"  {
    attributes_json = <<-EOF
    {
      "set_fqdn": "chef.${var.env_name}.login.gov",
      "login_dot_gov": {
        "live_certs": "${var.live_certs}"
      }
    }
    EOF
    environment = "${var.env_name}"
    run_list = [
    ]
    node_name = "chef.${var.env_name}"
    secret_key = "${file("${var.chef_databag_key_path}")}"
    server_url = "${var.chef_url}"
    recreate_client = true
    user_name = "${var.chef_id}"
    user_key = "${file("${var.chef_id_key_path}")}"
    version = "${var.chef_version}"
    fetch_chef_certificates = true
  }

#  # lock the fw down so that we can only ssh in via the jumphost
#  provisioner "file" {
#    source = "chef-iptables.rules"
#    destination = "/etc/iptables/rules.v4"
#  }
#  provisioner "file" {
#    source = "chef-iptables6.rules"
#    destination = "/etc/iptables/rules.v6"
#  }
#  provisioner "local-exec" {
#    command = "ssh -o StrictHostKeyChecking=no ubuntu@${aws_instance.chef.public_ip} 'sudo aptitude install iptables-persistent'"
#  }
}

resource "aws_route53_record" "chef" {
  depends_on = ["aws_instance.chef"]
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name = "chef.login.gov.internal"
  type = "A"
  ttl = "300"
  records = ["${aws_instance.chef.private_ip}"]
}

resource "aws_route53_record" "chef-reverse" {
  depends_on = ["aws_instance.chef"]
  zone_id = "${aws_route53_zone.internal-reverse.zone_id}"
  name = "${format("%s.%s.16.172.in-addr.arpa", element(split(".", aws_instance.chef.private_ip), 3), element(split(".", aws_instance.chef.private_ip), 2) )}"

  type = "PTR"
  ttl = "300"
  records = ["chef.login.gov.internal"]
}

resource "aws_eip" "chef" {
  instance = "${aws_instance.chef.id}"
  vpc      = true
}
