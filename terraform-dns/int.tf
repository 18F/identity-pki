resource "aws_route53_record" "a_jumphost_int" {
  name = "jumphost.int.login.gov"
  records = ["${data.terraform_remote_state.app-int.jumphost-eip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "a_int" {
  name = "int.login.gov"
  records = ["${data.terraform_remote_state.app-int.idp_eip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "a_app_int" {
  name = "app.int.login.gov"
  records = ["${data.terraform_remote_state.app-int.app_eip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "a_chef_int" {
  name = "chef.int.login.gov"
  records = ["${data.terraform_remote_state.app-int.chef-eip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "a_elk_int" {
  name = "elk.int.login.gov"
  records = ["${data.terraform_remote_state.app-int.elk_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "a_jenkins_int" {
  name = "jenkins.int.login.gov"
  records = ["${data.terraform_remote_state.app-int.jenkins_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "a_worker_int" {
  name = "worker.int.login.gov"
  records = ["${data.terraform_remote_state.app-int.idp_worker_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_dash_int" {
  name = "dashboard.int.login.gov"
  records = ["${aws_route53_record.a_app_int.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_idp_int" {
  name = "idp.int.login.gov"
  records = ["${aws_route53_record.a_int.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_idv_int" {
  name = "idv.int.login.gov"
  records = ["${aws_route53_record.a_app_int.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_sp_int" {
  name = "sp.int.login.gov"
  records = ["${aws_route53_record.a_app_int.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_sp_python_int" {
  name = "sp-python.int.login.gov"
  records = ["${aws_route53_record.a_app_int.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_sp_rails_int" {
  name = "sp-rails.int.login.gov"
  records = ["${aws_route53_record.a_app_int.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_sp_sinatra_int" {
  name = "sp-sinatra.int.login.gov"
  records = ["${aws_route53_record.a_app_int.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}
