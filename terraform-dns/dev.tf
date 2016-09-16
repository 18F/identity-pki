resource "aws_route53_record" "a_dev" {
  name = "dev.login.gov"
  records = ["${data.terraform_remote_state.app-dev.aws_eip_app_public_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "a_worker_dev" {
  name = "worker.dev.login.gov"
  records = ["${data.terraform_remote_state.app-dev.aws_instance_worker_public_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "c_dash_dev" {
  name = "dashboard.dev.login.gov"
  records = ["${aws_route53_record.a_dev.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "c_idp_dev" {
  name = "idp.dev.login.gov"
  records = ["${aws_route53_record.a_dev.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "c_idv_dev" {
  name = "idv.dev.login.gov"
  records = ["${aws_route53_record.a_dev.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.zone_id}"
}


resource "aws_route53_record" "c_sp_dev" {
  name = "sp.dev.login.gov"
  records = ["${aws_route53_record.a_dev.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "c_sp_python_dev" {
  name = "sp-python.dev.login.gov"
  records = ["${aws_route53_record.a_dev.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "c_sp_rails_dev" {
  name = "sp-rails.dev.login.gov"
  records = ["${aws_route53_record.a_dev.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "c_sp_sinatra_dev" {
  name = "sp-sinatra.dev.login.gov"
  records = ["${aws_route53_record.a_dev.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.zone_id}"
}
