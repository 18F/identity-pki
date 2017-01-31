resource "aws_route53_record" "a_app_dev" {
  name = "app.dev.login.gov"
  records = ["${data.terraform_remote_state.app-dev.app_eip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "a_chef_dev" {
  name = "chef.dev.login.gov"
  records = ["${data.terraform_remote_state.app-dev.chef-eip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "a_elk_dev" {
  name = "elk.dev.login.gov"
  records = ["${data.terraform_remote_state.app-dev.elk_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "a_idp_dev" {
  name = "idp.dev.login.gov"
  records = ["${data.terraform_remote_state.app-dev.idp_eip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "a_jenkins_dev" {
  name = "jenkins.dev.login.gov"
  records = ["${data.terraform_remote_state.app-dev.jenkins_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "a_jumphost_dev" {
  name = "jumphost.dev.login.gov"
  records = ["${data.terraform_remote_state.app-dev.jumphost-eip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "a_worker_dev" {
  name = "worker.dev.login.gov"
  records = ["${data.terraform_remote_state.app-dev.idp_worker_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_alb_dev" {
  name = "dev.login.gov"
  records = ["${data.terraform_remote_state.app-dev.alb_hostname}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_dash_dev" {
  name = "dashboard.dev.login.gov"
  records = ["${aws_route53_record.a_app_dev.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_idv_dev" {
  name = "idv.dev.login.gov"
  records = ["${aws_route53_record.a_app_dev.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_sp_dev" {
  name = "sp.dev.login.gov"
  records = ["${aws_route53_record.a_app_dev.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_sp_python_dev" {
  name = "sp-python.dev.login.gov"
  records = ["${aws_route53_record.a_app_dev.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_sp_rails_dev" {
  name = "sp-rails.dev.login.gov"
  records = ["${aws_route53_record.a_app_dev.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_sp_sinatra_dev" {
  name = "sp-sinatra.dev.login.gov"
  records = ["${aws_route53_record.a_app_dev.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}
