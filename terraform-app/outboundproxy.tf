resource "aws_iam_role" "obproxy" {
  name = "${var.env_name}_obproxy_iam_role"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_from_vpc.json}"
}

resource "aws_iam_instance_profile" "obproxy" {
  name = "${var.env_name}_obproxy_instance_profile"
  role = "${aws_iam_role.obproxy.name}"
}

resource "aws_iam_role_policy" "obproxy" {
  name = "${var.env_name}_obproxy_iam_role_policy"
  role = "${aws_iam_role.obproxy.id}"
  policy = "${data.aws_iam_policy_document.sharedbucket.json}"
}

resource "aws_iam_role_policy" "obproxy-secrets" {
  name = "${var.env_name}-obproxy-secrets"
  role = "${aws_iam_role.obproxy.id}"
  policy = "${data.aws_iam_policy_document.secrets_role_policy.json}"
}

resource "aws_iam_role_policy" "obproxy-certificates" {
  name = "${var.env_name}-obproxy-certificates"
  role = "${aws_iam_role.obproxy.id}"
  policy = "${data.aws_iam_policy_document.certificates_role_policy.json}"
}

resource "aws_iam_role_policy" "obproxy-describe_instances" {
  name = "${var.env_name}-obproxy-describe_instances"
  role = "${aws_iam_role.obproxy.id}"
  policy = "${data.aws_iam_policy_document.describe_instances_role_policy.json}"
}

resource "aws_security_group" "obproxy" {
  description = "Allow inbound web traffic and whitelisted IP(s) for SSH"

  # allow outbound to the VPC so that we can get to db/redis/logstash/etc.
  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["${var.vpc_cidr_block}"]
  }

  # need 80/443 to get packages/gems/etc
  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # need 80/443 to get packages/gems/etc
  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 3128
    to_port = 3128
    protocol = "tcp"
    cidr_blocks = ["${var.vpc_cidr_block}"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_groups = [ "${aws_security_group.jumphost.id}", "${aws_security_group.jenkins.id}" ]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [ "${var.ci_sg_ssh_cidr_blocks}" ]
  }

  name = "${var.name}-obproxy-${var.env_name}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-obproxy_security_group-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "outboundproxy1" {
  availability_zone = "${var.region}a"
  cidr_block = "${var.obproxy1_subnet_cidr_block}"
  map_public_ip_on_launch = true

  tags {
    client = "${var.client}"
    Name = "${var.name}-obproxy1_subnet-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "outboundproxy2" {
  availability_zone = "${var.region}b"
  cidr_block = "${var.obproxy2_subnet_cidr_block}"
  map_public_ip_on_launch = true

  tags {
    client = "${var.client}"
    Name = "${var.name}-obproxy2_subnet-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}


# set up outbound proxy in AZ a
resource "aws_instance" "outboundproxy1" {
  count = "${var.outboundproxy_node_count}"
  ami = "${var.outboundproxy1_ami_id}"
  depends_on = ["aws_internet_gateway.default", "aws_route53_zone.internal","aws_instance.chef"]
  instance_type = "${var.instance_type_outboundproxy}"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.outboundproxy1.id}"
  iam_instance_profile = "${aws_iam_instance_profile.obproxy.id}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-outboundproxy1-${count.index}-${var.env_name}"
  }

  connection {
    bastion_host = "${aws_eip.jumphost.public_ip}"
    host = "${self.private_ip}"
    type = "ssh"
    user = "ubuntu"
  }

  vpc_security_group_ids = [ "${aws_security_group.obproxy.id}" ]

  provisioner "chef"  {
    attributes_json = <<-EOF
    {
      "set_fqdn": "outboundproxy1-${count.index}.${var.env_name}.${var.root_domain}",
      "login_dot_gov": {
        "live_certs": "${var.live_certs}"
      }
    }
    EOF
    environment = "${var.env_name}"
    run_list = [
      "role[outboundproxy]"
    ]
    node_name = "outboundproxy1-${count.index}.${var.env_name}"
    secret_key = "${file("${var.chef_databag_key_path}")}"
    server_url = "${var.chef_url}"
    recreate_client = true
    user_name = "${var.chef_id}"
    user_key = "${file("${var.chef_id_key_path}")}"
    version = "${var.chef_version}"
    fetch_chef_certificates = true
  }
}

# set up outbound proxy in AZ b
resource "aws_instance" "outboundproxy2" {
  count = "${var.outboundproxy_node_count}"
  ami = "${var.outboundproxy2_ami_id}"
  depends_on = ["aws_internet_gateway.default", "aws_route53_zone.internal","aws_instance.chef"]
  instance_type = "${var.instance_type_outboundproxy}"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.outboundproxy2.id}"
  iam_instance_profile = "${aws_iam_instance_profile.obproxy.id}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-outboundproxy2-${count.index}-${var.env_name}"
  }

  connection {
    bastion_host = "${aws_eip.jumphost.public_ip}"
    host = "${self.private_ip}"
    type = "ssh"
    user = "ubuntu"
  }

  vpc_security_group_ids = [ "${aws_security_group.obproxy.id}" ]

  provisioner "chef"  {
    attributes_json = <<-EOF
    {
      "set_fqdn": "outboundproxy2-${count.index}.${var.env_name}.${var.root_domain}",
      "login_dot_gov": {
        "live_certs": "${var.live_certs}"
      }
    }
    EOF
    environment = "${var.env_name}"
    run_list = [
      "role[outboundproxy]"
    ]
    node_name = "outboundproxy2-${count.index}.${var.env_name}"
    secret_key = "${file("${var.chef_databag_key_path}")}"
    server_url = "${var.chef_url}"
    recreate_client = true
    user_name = "${var.chef_id}"
    user_key = "${file("${var.chef_id_key_path}")}"
    version = "${var.chef_version}"
    fetch_chef_certificates = true
  }
}

resource "aws_route53_record" "outboundproxy1" {
  count = "${var.outboundproxy_node_count}"
  depends_on = ["aws_instance.outboundproxy1"]
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name = "outboundproxy1-${count.index}.login.gov.internal"
  type = "A"
  ttl = "300"
  records = ["${element(aws_instance.outboundproxy1.*.private_ip, count.index)}"]
}

resource "aws_route53_record" "outboundproxy2" {
  count = "${var.outboundproxy_node_count}"
  depends_on = ["aws_instance.outboundproxy2"]
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name = "outboundproxy2-${count.index}.login.gov.internal"
  type = "A"
  ttl = "300"
  records = ["${element(aws_instance.outboundproxy2.*.private_ip, count.index)}"]
}


# ELB here
resource "aws_elb" "outboundproxy" {
  name = "${var.name}-outboundproxy-elb-${var.env_name}"
  depends_on = ["aws_s3_bucket.proxylogbucket"]
  security_groups = ["${aws_security_group.obproxy.id}"]
  subnets = ["${aws_subnet.outboundproxy1.id}", "${aws_subnet.outboundproxy2.id}"]
  connection_draining         = true
  internal         = true

  access_logs {
    bucket = "login-gov-proxylogs-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"
    interval = 5
  }

  listener {
    instance_port = "3128"
    instance_protocol = "TCP"
    lb_port = "3128"
    lb_protocol = "TCP"
  }

  health_check {
    target = "TCP:3128"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
  }
}

resource "aws_elb_attachment" "outboundproxy1" {
  count = "${var.outboundproxy_node_count}"
  depends_on = ["aws_elb.outboundproxy"]
  elb = "${aws_elb.outboundproxy.id}"
  instance = "${element(aws_instance.outboundproxy1.*.id, count.index)}"
}

resource "aws_elb_attachment" "outboundproxy2" {
  count = "${var.outboundproxy_node_count}"
  depends_on = ["aws_elb.outboundproxy"]
  elb = "${aws_elb.outboundproxy.id}"
  instance = "${element(aws_instance.outboundproxy2.*.id, count.index)}"
}

resource "aws_route53_record" "obproxy" {
  depends_on = ["aws_elb.outboundproxy"]
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name = "obproxy.login.gov.internal"
  type = "CNAME"
  ttl = "300"
  records = ["${aws_elb.outboundproxy.dns_name}"]
}

# log bucket stuff here for elb logs
data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket" "proxylogbucket" {
  bucket = "login-gov-proxylogs-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"
  versioning {
    enabled = true
  }

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${data.aws_elb_service_account.main.arn}"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::login-gov-proxylogs-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}/AWSLogs/*"
    }
  ]
}
EOF

  lifecycle_rule {
    id = "proxylogexpire"
    prefix = ""
    enabled = true

    expiration {
      days = 90
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

data "aws_iam_policy_document" "sharedbucket" {
  statement {
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::login-gov-shared-data-${data.aws_caller_identity.current.account_id}"
    ]
  }
  statement {
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::login-gov-shared-data-${data.aws_caller_identity.current.account_id}/*"
    ]
  }
}

