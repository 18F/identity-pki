resource "aws_iam_role" "elk_iam_role" {
  name = "${var.env_name}_elk_iam_role"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_from_vpc.json}"
}

resource "aws_iam_instance_profile" "elk_instance_profile" {
  name = "${var.env_name}_elk_instance_profile"
  roles = ["${aws_iam_role.elk_iam_role.name}"]
}

data "aws_iam_policy_document" "logbucketpolicy" {
  statement {
    actions = [
      "logs:Describe*",
      "logs:Get*",
      "logs:TestMetricFilter",
      "logs:FilterLogEvents"
    ]
    resources = [ "*" ]
  }
  statement {
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::login-gov-${var.env_name}-logs"
    ]
  }
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "arn:aws:s3:::login-gov-${var.env_name}-logs/*"
    ]
  }
}

resource "aws_iam_role_policy" "elk_iam_role_policy" {
  name = "${var.env_name}_elk_iam_role_policy"
  role = "${aws_iam_role.elk_iam_role.id}"
  policy = "${data.aws_iam_policy_document.logbucketpolicy.json}"
}

resource "aws_s3_bucket" "logbucket" {
  bucket = "login-gov-${var.env_name}-logs"

  lifecycle_rule {
    id = "logexpire"
    prefix = ""
    enabled = true

    transition {
      days = 90
      storage_class = "STANDARD_IA"
    }
    transition {
      days = 365
        storage_class = "GLACIER"
    }
    expiration {
      days = 1095
    }
  }
}

resource "aws_instance" "elk" {
  ami = "${var.default_ami_id}"
  depends_on = ["aws_internet_gateway.default", "aws_route53_record.chef", "aws_route53_record.es"]
  instance_type = "${var.instance_type_elk}"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.admin.id}"
  iam_instance_profile = "${aws_iam_instance_profile.elk_instance_profile.id}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-elk-${var.env_name}"
  }

  connection {
    type = "ssh"
    user = "ubuntu"
    host = "${self.private_ip}"
    bastion_host = "${aws_eip.jumphost.public_ip}"
  }

  vpc_security_group_ids = [ "${aws_security_group.elk.id}" ]

  provisioner "chef"  {
    attributes_json = <<-EOF
    {
      "set_fqdn": "elk.${var.env_name}.login.gov",
      "login_dot_gov": {
        "live_certs": "${var.live_certs}"
      }
    }
    EOF
    environment = "${var.env_name}"
    run_list = [
      "role[base]",
      "recipe[identity-elk]"
    ]
    node_name = "elk.${var.env_name}"
    secret_key = "${file("${var.chef_databag_key_path}")}"
    server_url = "${var.chef_url}"
    recreate_client = true
    user_name = "${var.chef_id}"
    user_key = "${file("${var.chef_id_key_path}")}"
    version = "${var.chef_version}"
    fetch_chef_certificates = true
  }
}

resource "aws_route53_record" "elk" {
   zone_id = "${aws_route53_zone.internal.zone_id}"
   name = "elk.login.gov.internal"
   type = "A"
   ttl = "300"
   records = ["${aws_instance.elk.private_ip}"]
}

resource "aws_instance" "es" {
  count = "${var.esnodes}"
  ami = "${var.default_ami_id}"
  depends_on = ["aws_internet_gateway.default", "aws_route53_record.chef"]
  instance_type = "t2.medium"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.admin.id}"
  iam_instance_profile = "${aws_iam_instance_profile.elk_instance_profile.id}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-es-${var.env_name}"
  }

  connection {
    type = "ssh"
    user = "ubuntu"
    host = "${self.private_ip}"
    bastion_host = "${aws_eip.jumphost.public_ip}"
  }

  # We will mount this on /var/lib/elasticsearch when we notice that we are running out of space on stuff
  #ebs_block_device {
  #  device_name = "/dev/sdg"
  #  volume_size = 40
  #  volume_type = "gp2"
  #  encrypted = true
  #  delete_on_termination = true
  #}

  lifecycle {
    ignore_changes = ["ebs_block_device"]
  }

  vpc_security_group_ids = [ "${aws_security_group.elk.id}" ]

  provisioner "chef"  {
    attributes_json = <<-EOF
    {
      "set_fqdn": "es${count.index}.${var.env_name}.login.gov"
    }
    EOF
    environment = "${var.env_name}"
    run_list = [
      "role[base]",
      "recipe[identity-elk::es]"
    ]
    node_name = "es${count.index}.${var.env_name}"
    secret_key = "${file("${var.chef_databag_key_path}")}"
    server_url = "${var.chef_url}"
    recreate_client = true
    user_name = "${var.chef_id}"
    user_key = "${file("${var.chef_id_key_path}")}"
    version = "${var.chef_version}"
    fetch_chef_certificates = true
  }
}

resource "aws_route53_record" "eshost" {
  count = "${var.esnodes}"
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name = "es${count.index}.login.gov.internal"
  type = "A"
  ttl = "300"
  records = ["${element(aws_instance.es.*.private_ip, count.index)}"]
}

resource "aws_route53_record" "es" {
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name = "es.login.gov.internal"
  type = "A"
  ttl = "300"
  records = ["${aws_instance.es.*.private_ip}"]
}

