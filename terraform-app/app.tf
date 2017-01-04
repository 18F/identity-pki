resource "aws_instance" "app" {
  ami = "${var.ami_id}"
  depends_on = ["aws_internet_gateway.default", "aws_route53_record.chef", "aws_route53_record.elk"]
  instance_type = "t2.medium"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.app.id}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-app-${var.env_name}"
  }

  connection {
    type = "ssh"
    user = "ubuntu"
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

resource "aws_db_instance" "app" {
  allocated_storage = "${var.rds_storage}"
  db_subnet_group_name = "${aws_db_subnet_group.default.id}"
  depends_on = ["aws_security_group.db", "aws_subnet.db1", "aws_subnet.db2", "aws_db_parameter_group.force_ssl"]
  engine = "${var.rds_engine}"
  identifier = "${var.name}-${var.env_name}-app"
  instance_class = "${var.rds_instance_class}"
  parameter_group_name = "${var.name}-force-ssl-${var.env_name}"
  storage_encrypted = true
  password = "${var.rds_password}"
  username = "${var.rds_username}"

  tags {
    client = "${var.client}"
    Name = "${var.name}_${var.env_name}"
  }

  vpc_security_group_ids = ["${aws_security_group.db.id}"]
}

resource "aws_eip" "app" {
  instance = "${aws_instance.app.id}"
  vpc      = true
}
