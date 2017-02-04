resource "aws_instance" "app" {
  ami = "${var.ami_id}"
  count = "${var.apps_enabled == true ? 1 : 0}"
  depends_on = ["aws_internet_gateway.default", "aws_route53_record.chef", "aws_route53_record.elk"]
  instance_type = "${var.instance_type_app}"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.app.id}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-app-${var.env_name}"
  }

  connection {
    type = "ssh"
    user = "ubuntu"
    host = "${self.private_ip}"
    bastion_host = "${aws_eip.jumphost.public_ip}"
  }

  vpc_security_group_ids = [ "${aws_security_group.default.id}" ]

  provisioner "chef"  {
    attributes_json = <<-EOF
    {
      "set_fqdn": "app.${var.env_name}.login.gov",
      "login_dot_gov": {
        "live_certs": "${var.live_certs}"
      }
    }
    EOF
    environment = "${var.env_name}"
    run_list = [
      "role[base]",
      "recipe[login_dot_gov::install_app_role]"
    ]
    node_name = "app.${var.env_name}"
    secret_key = "${file("${var.chef_databag_key_path}")}"
    server_url = "${var.chef_url}"
    recreate_client = true
    user_name = "${var.chef_id}"
    user_key = "${file("${var.chef_id_key_path}")}"
    version = "${var.chef_version}"
    fetch_chef_certificates = true
  }
}

resource "aws_eip" "app" {
  count = "${var.apps_enabled == true ? 1 : 0}"
  instance = "${aws_instance.app.id}"
  vpc      = true
}

resource "aws_route53_record" "a_app" {
  count = "${var.apps_enabled == true ? 1 : 0}"
  name = "app.${var.env_name}.login.gov"
  records = ["${aws_eip.app.public_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${var.route53_id}"
}

resource "aws_route53_record" "c_dash" {
  count = "${var.apps_enabled == true ? 1 : 0}"
  name = "dashboard.${var.env_name}.login.gov"
  records = ["app.${var.env_name}.login.gov"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.route53_id}"
}

resource "aws_route53_record" "c_sp" {
  count = "${var.apps_enabled == true ? 1 : 0}"
  name = "sp.${var.env_name}.login.gov"
  records = ["app.${var.env_name}.login.gov"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.route53_id}"
}

resource "aws_route53_record" "c_sp_python" {
  count = "${var.apps_enabled == true ? 1 : 0}"
  name = "sp-python.${var.env_name}.login.gov"
  records = ["app.${var.env_name}.login.gov"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.route53_id}"
}

resource "aws_route53_record" "c_sp_rails" {
  count = "${var.apps_enabled == true ? 1 : 0}"
  name = "sp-rails.${var.env_name}.login.gov"
  records = ["app.${var.env_name}.login.gov"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.route53_id}"
}

resource "aws_route53_record" "c_sp_sinatra" {
  count = "${var.apps_enabled == true ? 1 : 0}"
  name = "sp-sinatra.${var.env_name}.login.gov"
  records = ["app.${var.env_name}.login.gov"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.route53_id}"
}

