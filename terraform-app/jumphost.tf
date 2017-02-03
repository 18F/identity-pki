resource "aws_instance" "jumphost" {
  ami = "${var.default_ami_id}"
  depends_on = ["aws_internet_gateway.default", "aws_route53_zone.internal","aws_instance.chef","aws_instance.elk"]
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

