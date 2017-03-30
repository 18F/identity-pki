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

  vpc_security_group_ids = [ "${aws_security_group.app.id}" ]

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

resource "aws_db_instance" "default" {
  allocated_storage = "${var.rds_storage}"
  count = "${var.apps_enabled == true ? 1 : 0}"
  db_subnet_group_name = "${aws_db_subnet_group.default.id}"
  depends_on = ["aws_security_group.db", "aws_subnet.db1", "aws_subnet.db2"]
  engine = "${var.rds_engine}"
  identifier = "${var.name}-${var.env_name}"
  instance_class = "${var.rds_instance_class}"
  password = "${var.rds_password}"
  username = "${var.rds_username}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-${var.env_name}"
  }

  vpc_security_group_ids = ["${aws_security_group.db.id}"]
}

resource "aws_db_subnet_group" "default" {
  description = "${var.env_name} env subnet group for login.gov"
  name = "${var.name}-db-${var.env_name}"
  subnet_ids = ["${aws_subnet.db1.id}", "${aws_subnet.db2.id}"]

  tags {
    client = "${var.client}"
    Name = "${var.name}-${var.env_name}"
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

resource "aws_route53_record" "a_app_internal" {
  count = "${var.apps_enabled == true ? 1 : 0}"
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name = "apps_host.login.gov.internal"
  type = "A"
  ttl = "300"
  records = ["${aws_instance.app.private_ip}"]
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

resource "aws_route53_record" "postgres" {
  count = "${var.apps_enabled == true ? 1 : 0}"
  name = "postgres"
  records = ["${replace(aws_db_instance.default.endpoint,":5432","")}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.internal.zone_id}"
}
