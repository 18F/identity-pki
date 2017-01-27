resource "aws_route53_record" "a_jumphost_staging" {
  name = "jumphost.staging.login.gov"
  records = ["${data.terraform_remote_state.app-staging.jumphost-eip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "a_staging" {
  name = "staging.login.gov"
  records = ["${data.terraform_remote_state.app-staging.idp_eip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "a_app_staging" {
  name = "app.staging.login.gov"
  records = ["${data.terraform_remote_state.app-staging.app_eip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "a_chef_staging" {
  name = "chef.staging.login.gov"
  records = ["${data.terraform_remote_state.app-staging.chef-eip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "a_elk_staging" {
  name = "elk.staging.login.gov"
  records = ["${data.terraform_remote_state.app-staging.elk_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "a_jenkins_staging" {
  name = "jenkins.staging.login.gov"
  records = ["${data.terraform_remote_state.app-staging.jenkins_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "a_worker_staging" {
  name = "worker.staging.login.gov"
  records = ["${data.terraform_remote_state.app-staging.idp_worker_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_dash_staging" {
  name = "dashboard.staging.login.gov"
  records = ["${aws_route53_record.a_app_staging.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_idp_staging" {
  name = "idp.staging.login.gov"
  records = ["${aws_route53_record.a_staging.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_idv_staging" {
  name = "idv.staging.login.gov"
  records = ["${aws_route53_record.a_app_staging.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_sp_staging" {
  name = "sp.staging.login.gov"
  records = ["${aws_route53_record.a_app_staging.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_sp_python_staging" {
  name = "sp-python.staging.login.gov"
  records = ["${aws_route53_record.a_app_staging.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_sp_rails_staging" {
  name = "sp-rails.staging.login.gov"
  records = ["${aws_route53_record.a_app_staging.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_sp_sinatra_staging" {
  name = "sp-sinatra.staging.login.gov"
  records = ["${aws_route53_record.a_app_staging.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}
