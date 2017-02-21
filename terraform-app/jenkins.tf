data "aws_iam_policy_document" "allow_jenkins" {
  statement {
    sid = "allowJenkins"
    actions = [
      "sts:AssumeRole"
    ]
    principals = {
      type = "AWS"
      identifiers = ["${aws_instance.jenkins.id}"]
    }
  }
}

resource "aws_iam_role" "jenkins" {
  name = "${var.env_name}_jenkins"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_from_vpc.json}"
}

resource "aws_iam_instance_profile" "jenkins" {
  name = "${var.env_name}_jenkins"
  roles = ["${aws_iam_role.jenkins.name}"]
}

# XXX turned off because of https://github.com/hashicorp/terraform/issues/10500
#resource "aws_iam_policy_attachment" "jenkins" {
#  name = "${var.env_name}_jenkins"
#  roles = ["${aws_iam_role.jenkins.name}"]
#  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
#}

resource "aws_instance" "jenkins" {
  ami = "${var.ami_id}"
  depends_on = ["aws_internet_gateway.default", "aws_route53_record.chef", "aws_route53_record.elk"]
  instance_type = "${var.instance_type_jenkins}"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.admin.id}"
  iam_instance_profile = "${aws_iam_instance_profile.jenkins.name}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-jenkins-${var.env_name}"
  }

  connection {
    type = "ssh"
    user = "ubuntu"
    host = "${self.private_ip}"
    bastion_host = "${aws_eip.jumphost.public_ip}"
  }

  vpc_security_group_ids = [ "${aws_security_group.jenkins.id}" ]

  provisioner "chef"  {
    attributes_json = <<-EOF
    {
      "set_fqdn": "jenkins.${var.env_name}.login.gov",
      "login_dot_gov": {
        "live_certs": "${var.live_certs}"
      }
    }
    EOF
    environment = "${var.env_name}"
    run_list = [
      "role[base]",
      "recipe[identity-jenkins]"
    ]
    node_name = "jenkins.${var.env_name}"
    secret_key = "${file("${var.chef_databag_key_path}")}"
    server_url = "${var.chef_url}"
    recreate_client = true
    user_name = "${var.chef_id}"
    user_key = "${file("${var.chef_id_key_path}")}"
    version = "${var.chef_version}"
    fetch_chef_certificates = true
  }

  # XXX when https://github.com/hashicorp/terraform/issues/10500 gets fixed, remove this
  provisioner "local-exec" {
    command = "aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess --role-name ${aws_iam_role.jenkins.name}"
  }
}

resource "aws_route53_record" "jenkins" {
   zone_id = "${aws_route53_zone.internal.zone_id}"
   name = "jenkins.login.gov.internal"
   type = "A"
   ttl = "300"
   records = ["${aws_instance.jenkins.private_ip}"]
}

resource "aws_eip" "jenkins" {
  instance = "${aws_instance.jenkins.id}"
  vpc      = true
}
