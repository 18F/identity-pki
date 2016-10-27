resource "aws_route53_record" "a_tf" {
  name = "tf.login.gov"
  records = ["${data.terraform_remote_state.app-tf.aws_eip_app_public_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "a_worker_tf" {
  name = "worker.tf.login.gov"
  records = ["${data.terraform_remote_state.app-tf.aws_instance_worker_public_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "c_dash_tf" {
  name = "dashboard.tf.login.gov"
  records = ["${aws_route53_record.a_tf.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "c_idp_tf" {
  name = "idp.tf.login.gov"
  records = ["${aws_route53_record.a_tf.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "c_idv_tf" {
  name = "idv.tf.login.gov"
  records = ["${aws_route53_record.a_tf.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "c_sp_tf" {
  name = "sp.tf.login.gov"
  records = ["${aws_route53_record.a_tf.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "c_sp_python_tf" {
  name = "sp-python.tf.login.gov"
  records = ["${aws_route53_record.a_tf.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "c_sp_rails_tf" {
  name = "sp-rails.tf.login.gov"
  records = ["${aws_route53_record.a_tf.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "c_sp_sinatra_tf" {
  name = "sp-sinatra.tf.login.gov"
  records = ["${aws_route53_record.a_tf.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.zone_id}"
}
