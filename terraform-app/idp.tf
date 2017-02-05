resource "aws_instance" "idp1" {
  ami = "${var.ami_id}"
  count = "${var.idp_node_count}"
  depends_on = ["aws_internet_gateway.default", "aws_route53_record.chef", "aws_route53_record.elk", "aws_elasticache_cluster.idp", "aws_db_instance.idp"]
  instance_type = "${var.instance_type_idp}"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.idp1.id}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-idp-${var.env_name}"
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
      "set_fqdn": "idp.${var.env_name}.login.gov",
      "login_dot_gov": {
        "live_certs": "${var.live_certs}"
      }
    }
    EOF
    environment = "${var.env_name}"
    run_list = [
      "role[base]",
      "recipe[login_dot_gov::install_idp_role]"
    ]
    node_name = "idp1.${count.index}.${var.env_name}"
    secret_key = "${file("${var.chef_databag_key_path}")}"
    server_url = "${var.chef_url}"
    recreate_client = true
    user_name = "${var.chef_id}"
    user_key = "${file("${var.chef_id_key_path}")}"
    version = "${var.chef_version}"
    fetch_chef_certificates = true
  }
}

resource "aws_route53_record" "idp1" {
  count = "${var.idp_node_count}"
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name = "idp1-${count.index}.login.gov.internal"
  type = "A"
  ttl = "300"
  records = ["${element(aws_instance.idp1.*.private_ip, count.index)}"]
}

resource "aws_instance" "idp2" {
  ami = "${var.ami_id}"
  count = "${var.idp_node_count}"
  depends_on = ["aws_internet_gateway.default", "aws_route53_record.chef", "aws_route53_record.elk", "aws_elasticache_cluster.idp", "aws_db_instance.idp"]
  instance_type = "${var.instance_type_idp}"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.idp2.id}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-idp-${var.env_name}"
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
      "set_fqdn": "idp.${var.env_name}.login.gov",
      "login_dot_gov": {
        "live_certs": "${var.live_certs}"
      }
    }
    EOF
    environment = "${var.env_name}"
    run_list = [
      "role[base]",
      "recipe[login_dot_gov::install_idp_role]"
    ]
    node_name = "idp2.${count.index}.${var.env_name}"
    secret_key = "${file("${var.chef_databag_key_path}")}"
    server_url = "${var.chef_url}"
    recreate_client = true
    user_name = "${var.chef_id}"
    user_key = "${file("${var.chef_id_key_path}")}"
    version = "${var.chef_version}"
    fetch_chef_certificates = true
  }
}

resource "aws_route53_record" "idp2" {
  count = "${var.idp_node_count}"
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name = "idp2-${count.index}.login.gov.internal"
  type = "A"
  ttl = "300"
  records = ["${element(aws_instance.idp2.*.private_ip, count.index)}"]
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
  depends_on = ["aws_internet_gateway.default", "aws_route53_record.chef", "aws_route53_record.elk", "aws_elasticache_cluster.idp", "aws_db_instance.idp"]
  instance_type = "${var.instance_type_worker}"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.idp1.id}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-worker-${var.env_name}"
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

resource "aws_route53_record" "worker" {
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name = "worker.login.gov.internal"
  type = "A"
  ttl = "300"
  records = ["${aws_instance.idp_worker.private_ip}"]
}

resource "aws_db_instance" "idp" {
  allocated_storage = "${var.rds_storage}"
  db_subnet_group_name = "${aws_db_subnet_group.default.id}"
  depends_on = ["aws_security_group.db", "aws_subnet.db1", "aws_subnet.db2", "aws_db_parameter_group.force_ssl"]
  engine = "${var.rds_engine}"
  identifier = "${var.name}-${var.env_name}-idp"
  instance_class = "${var.rds_instance_class}"
  multi_az = true
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

resource "aws_elasticache_cluster" "idp" {
  cluster_id = "login-idp-${var.env_name}"
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

resource "aws_route53_record" "redis" {
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name = "redis"

  type = "CNAME"
  ttl = "300"
  records = ["${aws_elasticache_cluster.idp.cache_nodes.0.address}"]
}

resource "aws_route53_record" "idp-postgres" {
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name = "idp-postgres"

  type = "CNAME"
  ttl = "300"
  records = ["${replace(aws_db_instance.idp.endpoint,":5432","")}"]
}
