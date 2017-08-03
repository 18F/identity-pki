resource "aws_db_instance" "idp" {
  allocated_storage = "${var.rds_storage}"
  apply_immediately = true
  backup_retention_period = "${var.rds_backup_retention_period}"
  backup_window = "${var.rds_backup_window}"
  db_subnet_group_name = "${aws_db_subnet_group.default.id}"
  # TODO: these deps prevent cleanly destroying an RDS instance, and they should probably be removed
  depends_on = ["aws_security_group.db", "aws_subnet.db1", "aws_subnet.db2", "aws_db_parameter_group.force_ssl"]
  engine = "${var.rds_engine}"
  engine_version = "${var.rds_engine_version}"
  identifier = "${var.name}-${var.env_name}-idp"
  instance_class = "${var.rds_instance_class}"
  maintenance_window = "${var.rds_maintenance_window}"
  multi_az = true
  parameter_group_name = "${aws_db_parameter_group.force_ssl.name}"
  password = "${var.rds_password}"
  storage_encrypted = true
  username = "${var.rds_username}"

  # change this to true to allow upgrading engine versions
  allow_major_version_upgrade = false

  tags {
    client = "${var.client}"
    Name = "${var.name}-${var.env_name}"
  }

  vpc_security_group_ids = ["${aws_security_group.db.id}"]

  # If you want to destroy your database, you need to do this in two phases:
  # 1. Uncomment `skip_final_snapshot=true` and
  #    comment `prevent_destroy=true` below.
  # 2. Perform a terraform/deploy "apply" with the additional
  #    argument of "-target=aws_db_instance.idp" to mark the database
  #    as not requiring a final snapshot.
  # 3. Perform a terraform/deploy "destroy" as needed.
  #
  #skip_final_snapshot = true
  lifecycle {
    prevent_destroy = true

    # we set the password by hand so it doesn't end up in the state file
    ignore_changes = ["password"]
  }
}

resource "aws_db_parameter_group" "force_ssl" {
  name = "${var.name}-idp-force-ssl-${var.env_name}-${var.rds_engine}${replace(var.rds_engine_version_short, ".", "")}"
  # Before changing this value, make sure the parameters are correct for the
  # version you are upgrading to.  See
  # http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.html.
  family = "${var.rds_engine}${var.rds_engine_version_short}"

  parameter {
    name = "rds.force_ssl"
    value = "1"
    apply_method = "pending-reboot"
  }

  lifecycle {
    create_before_destroy = true
  }
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
}

resource "aws_iam_instance_profile" "idp" {
  name = "${var.env_name}_idp_instance_profile"
  roles = ["${aws_iam_role.idp.name}"]
}

resource "aws_iam_role" "idp" {
  name = "${var.env_name}_idp_iam_role"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_from_vpc.json}"
}

resource "aws_iam_role_policy" "idp-citadel" {
  name = "${var.env_name}-idp-citadel"
  role = "${aws_iam_role.idp.id}"
  policy = "${data.aws_iam_policy_document.secrets_role_policy.json}"
}

resource "aws_instance" "idp1" {
  count = "${var.non_asg_idp_enabled * var.idp_node_count}"
  ami = "${var.idp1_ami_id}"
  depends_on = ["aws_internet_gateway.default", "aws_route53_record.chef", "aws_route53_record.elk", "aws_elasticache_cluster.idp", "aws_db_instance.idp"]
  instance_type = "${var.instance_type_idp}"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.idp1.id}"
  iam_instance_profile = "${aws_iam_instance_profile.idp.id}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-idp1-${count.index}-${var.env_name}"
    prefix = "idp"
    domain = "${var.env_name}.login.gov"
  }

  lifecycle {
    ignore_changes = ["ami"]
  }

  connection {
    bastion_host = "${aws_eip.jumphost.public_ip}"
    host = "${self.private_ip}"
    script_path = "/home/ubuntu/tf_remote_exec.sh"
    type = "ssh"
    user = "ubuntu"
  }

  vpc_security_group_ids = [ "${aws_security_group.idp.id}" ]

  provisioner "file" {
    content     = "${tls_private_key.idp_tls_private_key.private_key_pem}"
    destination = "~/idp-key.pem"
  }

  provisioner "file" {
    content     = "${tls_self_signed_cert.idp_tls_cert.cert_pem}"
    destination = "~/idp-cert.pem"
  }

  # move cert and keys to /etc/ssl and remove tf_remote_exec.sh provisioner script
  provisioner "remote-exec" {
    inline = [
      "sudo mv /home/ubuntu/*cert.pem /etc/ssl/certs/",
      "sudo mv /home/ubuntu/*key.pem /etc/ssl/private/"
    ]
  }

  provisioner "chef"  {
    attributes_json = <<-EOF
    {
      "set_fqdn": "idp1-${count.index}.${var.env_name}.login.gov",
      "login_dot_gov": {
        "live_certs": "${var.live_certs}"
      }
    }
    EOF
    environment = "${var.env_name}"
    run_list = [
      "role[base]"
    ]
    node_name = "idp1-${count.index}.${var.env_name}"
    secret_key = "${file("${var.chef_databag_key_path}")}"
    server_url = "${var.chef_url}"
    recreate_client = true
    user_name = "${var.chef_id}"
    user_key = "${file("${var.chef_id_key_path}")}"
    version = "${var.chef_version}"
    fetch_chef_certificates = true
  }
}

resource "aws_instance" "idp2" {
  count = "${var.non_asg_idp_enabled * var.idp_node_count}"
  ami = "${var.idp2_ami_id}"
  depends_on = ["aws_internet_gateway.default", "aws_route53_record.chef", "aws_route53_record.elk", "aws_elasticache_cluster.idp", "aws_db_instance.idp"]
  instance_type = "${var.instance_type_idp}"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.idp2.id}"
  iam_instance_profile = "${aws_iam_instance_profile.idp.id}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-idp2-${count.index}-${var.env_name}"
    prefix = "idp"
    domain = "${var.env_name}.login.gov"
  }

  lifecycle {
    ignore_changes = ["ami"]
  }

  connection {
    bastion_host = "${aws_eip.jumphost.public_ip}"
    host = "${self.private_ip}"
    script_path = "/home/ubuntu/tf_remote_exec.sh"
    type = "ssh"
    user = "ubuntu"
  }

  vpc_security_group_ids = [ "${aws_security_group.idp.id}" ]

  provisioner "file" {
    content     = "${tls_private_key.idp_tls_private_key.private_key_pem}"
    destination = "~/idp-key.pem"
  }

  provisioner "file" {
    content     = "${tls_self_signed_cert.idp_tls_cert.cert_pem}"
    destination = "~/idp-cert.pem"
  }

  # move cert and keys to /etc/ssl and remove tf_remote_exec.sh provisioner script
  provisioner "remote-exec" {
    inline = [
      "sudo mv /home/ubuntu/*cert.pem /etc/ssl/certs/",
      "sudo mv /home/ubuntu/*key.pem /etc/ssl/private/"
    ]
  }

  provisioner "chef"  {
    attributes_json = <<-EOF
    {
      "set_fqdn": "idp2-${count.index}.${var.env_name}.login.gov",
      "login_dot_gov": {
        "live_certs": "${var.live_certs}"
      }
    }
    EOF
    environment = "${var.env_name}"
    run_list = [
      "role[base]"
    ]
    node_name = "idp2-${count.index}.${var.env_name}"
    secret_key = "${file("${var.chef_databag_key_path}")}"
    server_url = "${var.chef_url}"
    recreate_client = true
    user_name = "${var.chef_id}"
    user_key = "${file("${var.chef_id_key_path}")}"
    version = "${var.chef_version}"
    fetch_chef_certificates = true
  }
}

resource "aws_instance" "idp_worker" {
  count = "${var.non_asg_idp_worker_enabled * var.idp_worker_count}"
  ami = "${element(var.worker_ami_list, count.index % length(var.worker_ami_list))}"
  depends_on = ["aws_internet_gateway.default", "aws_route53_record.chef", "aws_route53_record.elk", "aws_elasticache_cluster.idp", "aws_db_instance.idp"]
  instance_type = "${var.instance_type_worker}"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.idp1.id}"
  iam_instance_profile = "${aws_iam_instance_profile.idp.id}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-worker${count.index}-${var.env_name}"
    prefix = "worker"
    domain = "${var.env_name}.login.gov"
  }

  lifecycle {
    ignore_changes = ["ami"]
  }

  connection {
    type = "ssh"
    user = "ubuntu"
    host = "${self.private_ip}"
    bastion_host = "${aws_eip.jumphost.public_ip}"
  }

  vpc_security_group_ids = [ "${aws_security_group.idp.id}" ]

  provisioner "chef"  {
    attributes_json = <<-EOF
    {
      "set_fqdn": "worker${count.index}.${var.env_name}.login.gov",
      "login_dot_gov": {
        "live_certs": "${var.live_certs}"
      }
    }
    EOF
    environment = "${var.env_name}"
    run_list = [
      "role[base]"
    ]
    node_name = "worker-${count.index}.${var.env_name}"
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
  count = "${var.non_asg_idp_enabled * var.idp_node_count}"
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name = "idp1-${count.index}.login.gov.internal"
  type = "A"
  ttl = "300"
  records = ["${element(aws_instance.idp1.*.private_ip, count.index)}"]
}

resource "aws_route53_record" "idp2" {
  count = "${var.non_asg_idp_enabled * var.idp_node_count}"
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name = "idp2-${count.index}.login.gov.internal"
  type = "A"
  ttl = "300"
  records = ["${element(aws_instance.idp2.*.private_ip, count.index)}"]
}

resource "aws_route53_record" "idp-postgres" {
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name = "idp-postgres"

  type = "CNAME"
  ttl = "300"
  records = ["${replace(aws_db_instance.idp.endpoint,":5432","")}"]
}

resource "aws_route53_record" "redis" {
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name = "redis"

  type = "CNAME"
  ttl = "300"
  records = ["${aws_elasticache_cluster.idp.cache_nodes.0.address}"]
}

# TODO: this record is deprecated and should be removed
resource "aws_route53_record" "worker" {
  count = "${var.non_asg_idp_worker_enabled}"
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name = "worker.login.gov.internal"
  type = "A"
  ttl = "300"
  records = ["${aws_instance.idp_worker.0.private_ip}"]
}

resource "aws_route53_record" "workers" {
  count = "${var.non_asg_idp_worker_enabled * var.idp_worker_count}"
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name = "worker-${count.index}.login.gov.internal"
  type = "A"
  ttl = "300"
  records = ["${element(aws_instance.idp_worker.*.private_ip, count.index)}"]
}

resource "tls_private_key" "idp_tls_private_key" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "idp_tls_cert" {
    key_algorithm = "RSA"
    private_key_pem = "${tls_private_key.idp_tls_private_key.private_key_pem}"

    subject {
        common_name = "idp.login.gov"
        organization = "18f"
    }

    validity_period_hours = 1440

    allowed_uses = [
        "key_encipherment",
        "digital_signature",
        "server_auth"
    ]
}
