resource "aws_route53_record" "a_pt" {
  name = "pt.login.gov"
  records = ["${data.terraform_remote_state.app-pt.aws_eip_app_public_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "a_worker_pt" {
  name = "worker.pt.login.gov"
  records = ["${data.terraform_remote_state.app-pt.aws_instance_worker_public_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "a_chef_pt" {
  name = "chef.pt.login.gov"
  records = ["${data.terraform_remote_state.app-pt.aws_eip_chef_public_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "a_elk_pt" {
  name = "chef.pt.login.gov"
  records = ["${data.terraform_remote_state.app-pt.aws_instance_elk_public_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "a_jenkins_pt" {
  name = "chef.pt.login.gov"
  records = ["${data.terraform_remote_state.app-pt.aws_instance_jenkins_public_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "c_dash_pt" {
  name = "dashboard.pt.login.gov"
  records = ["${aws_route53_record.a_pt.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "c_idp_pt" {
  name = "idp.pt.login.gov"
  records = ["${aws_route53_record.a_pt.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "c_idv_pt" {
  name = "idv.pt.login.gov"
  records = ["${aws_route53_record.a_pt.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "c_sp_pt" {
  name = "sp.pt.login.gov"
  records = ["${aws_route53_record.a_pt.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "c_sp_python_pt" {
  name = "sp-python.pt.login.gov"
  records = ["${aws_route53_record.a_pt.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "c_sp_rails_pt" {
  name = "sp-rails.pt.login.gov"
  records = ["${aws_route53_record.a_pt.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "c_sp_sinatra_pt" {
  name = "sp-sinatra.pt.login.gov"
  records = ["${aws_route53_record.a_pt.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.zone_id}"
}
