resource "aws_route53_record" "a_qa" {
  name = "qa.login.gov"
  records = ["${data.terraform_remote_state.app-qa.aws_eip_app_public_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "a_worker_qa" {
  name = "worker.qa.login.gov"
  records = ["${data.terraform_remote_state.app-qa.aws_instance_worker_public_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "a_chef_qa" {
  name = "chef.qa.login.gov"
  records = ["${data.terraform_remote_state.app-qa.aws_eip_chef_public_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "a_elk_qa" {
  name = "chef.qa.login.gov"
  records = ["${data.terraform_remote_state.app-qa.aws_instance_elk_public_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "a_jenkins_qa" {
  name = "chef.qa.login.gov"
  records = ["${data.terraform_remote_state.app-qa.aws_instance_jenkins_public_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "c_dash_qa" {
  name = "dashboard.qa.login.gov"
  records = ["${aws_route53_record.a_qa.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "c_idp_qa" {
  name = "idp.qa.login.gov"
  records = ["${aws_route53_record.a_qa.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "c_idv_qa" {
  name = "idv.qa.login.gov"
  records = ["${aws_route53_record.a_qa.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "c_sp_qa" {
  name = "sp.qa.login.gov"
  records = ["${aws_route53_record.a_qa.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "c_sp_python_qa" {
  name = "sp-python.qa.login.gov"
  records = ["${aws_route53_record.a_qa.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "c_sp_rails_qa" {
  name = "sp-rails.qa.login.gov"
  records = ["${aws_route53_record.a_qa.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "c_sp_sinatra_qa" {
  name = "sp-sinatra.qa.login.gov"
  records = ["${aws_route53_record.a_qa.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.zone_id}"
}
