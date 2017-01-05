resource "aws_instance" "idp" {
  ami = "${var.ami_id}"
  depends_on = ["aws_internet_gateway.default"]
  instance_type = "t2.medium"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.app.id}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-idp-${var.env_name}"
  }

  vpc_security_group_ids = [ "${aws_security_group.default.id}" ]
}

resource "aws_db_parameter_group" "force_ssl" {
  name = "${var.name}-idp-force-ssl-${var.env_name}"
  family = "postgres9.5"

  parameter {
    name = "rds.force_ssl"
    value = "1"
    apply_method = "pending-reboot"
  }
}

resource "aws_instance" "idp_worker" {
  ami = "${var.ami_id}"
  depends_on = ["aws_internet_gateway.default", "aws_route53_record.chef", "aws_route53_record.elk"]
  instance_type = "t2.medium"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.app.id}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-worker-${var.env_name}"
  }

  connection {
    type = "ssh"
    user = "ubuntu"
  }

  vpc_security_group_ids = [ "${aws_security_group.default.id}" ]

  provisioner "chef"  {
    attributes_json = <<-EOF
    {
      "set_fqdn": "worker.${var.env_name}.login.gov",
      "login_dot_gov": {
        "live_certs": "${var.live_certs}"
      }
    }
    EOF
    environment = "${var.env_name}"
    run_list = [
      "role[base]",
      "recipe[login_dot_gov::install_worker_role]"
    ]
    node_name = "worker.${var.env_name}"
    secret_key = "${file("${var.chef_databag_key_path}")}"
    server_url = "${var.chef_url}"
    recreate_client = true
    user_name = "${var.chef_id}"
    user_key = "${file("${var.chef_id_key_path}")}"
    version = "${var.chef_version}"
    fetch_chef_certificates = true
  }

}

resource "aws_db_instance" "idp" {
  allocated_storage = "${var.rds_storage}"
  db_subnet_group_name = "${aws_db_subnet_group.default.id}"
  depends_on = ["aws_security_group.db", "aws_subnet.db1", "aws_subnet.db2", "aws_db_parameter_group.force_ssl"]
  engine = "${var.rds_engine}"
  identifier = "${var.name}-${var.env_name}-idp"
  instance_class = "${var.rds_instance_class}"
  parameter_group_name = "${var.name}-idp-force-ssl-${var.env_name}"
  storage_encrypted = true
  password = "${var.rds_password}"
  username = "${var.rds_username}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-${var.env_name}"
  }

  vpc_security_group_ids = ["${aws_security_group.db.id}"]
}

resource "aws_eip" "idp" {
  instance = "${aws_instance.idp.id}"
  vpc      = true
}

resource "aws_elasticache_cluster" "idp" {
  cluster_id = "login-idp-ecache-${var.env_name}"
  engine = "redis"
  node_type = "cache.t2.micro"
  num_cache_nodes = 1
  parameter_group_name = "default.redis3.2"
  port = 6379
  security_group_ids = ["${aws_security_group.cache.id}"]
  subnet_group_name = "${aws_elasticache_subnet_group.idp.name}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-elasticache_cluster-${var.env_name}"
  }
}

resource "aws_route53_record" "idp-postgres" {
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name = "idp-postgres"

  type = "CNAME"
  ttl = "300"
  records = ["${replace(aws_db_instance.idp.endpoint,":5432","")}"]
}

