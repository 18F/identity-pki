resource "aws_route53_record" "a_chef" {
  name = "chef.login.gov"
  records = ["${data.terraform_remote_state.chef.aws_eip_public_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "c_chef" {
  name = "chef-tf.login.gov"
  records = ["${aws_route53_record.a_chef.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.zone_id}"
}
