resource "aws_route53_record" "a_chef_qa" {
  name = "chef.qa.login.gov"
  records = ["${data.terraform_remote_state.app-qa.chef-eip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "a_jenkins_qa" {
  name = "jenkins.qa.login.gov"
  records = ["${data.terraform_remote_state.app-qa.jenkins_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "a_elk_qa" {
  name = "elk.qa.login.gov"
  records = ["${data.terraform_remote_state.app-qa.elk_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "a_qa" {
  name = "qa.login.gov"
  records = ["${data.terraform_remote_state.app-qa.app_eip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "a_worker_qa" {
  name = "worker.qa.login.gov"
  records = ["${data.terraform_remote_state.app-qa.worker_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_dash_qa" {
  name = "dashboard.qa.login.gov"
  records = ["${aws_route53_record.a_qa.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_idp_qa" {
  name = "idp.qa.login.gov"
  records = ["${aws_route53_record.a_qa.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_idv_qa" {
  name = "idv.qa.login.gov"
  records = ["${aws_route53_record.a_qa.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_sp_qa" {
  name = "sp.qa.login.gov"
  records = ["${aws_route53_record.a_qa.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_sp_python_qa" {
  name = "sp-python.qa.login.gov"
  records = ["${aws_route53_record.a_qa.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_sp_rails_qa" {
  name = "sp-rails.qa.login.gov"
  records = ["${aws_route53_record.a_qa.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_sp_sinatra_qa" {
  name = "sp-sinatra.qa.login.gov"
  records = ["${aws_route53_record.a_qa.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}
