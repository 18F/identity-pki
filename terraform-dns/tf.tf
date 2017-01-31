resource "aws_route53_record" "a_app_tf" {
  name = "app.tf.login.gov"
  records = ["${data.terraform_remote_state.app-tf.app_eip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "a_chef_tf" {
  name = "chef.tf.login.gov"
  records = ["${data.terraform_remote_state.app-tf.chef-eip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "a_elk_tf" {
  name = "elk.tf.login.gov"
  records = ["${data.terraform_remote_state.app-tf.elk_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "a_idp_tf" {
  name = "idp.tf.login.gov"
  records = ["${data.terraform_remote_state.app-tf.idp_eip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "a_jenkins_tf" {
  name = "jenkins.tf.login.gov"
  records = ["${data.terraform_remote_state.app-tf.jenkins_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "a_jumphost_tf" {
  name = "jumphost.tf.login.gov"
  records = ["${data.terraform_remote_state.app-tf.jumphost-eip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "a_worker_tf" {
  name = "worker.tf.login.gov"
  records = ["${data.terraform_remote_state.app-tf.idp_worker_ip}"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_alb_tf" {
  name = "tf.login.gov"
  records = ["${data.terraform_remote_state.app-tf.alb_hostname}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_dash_tf" {
  name = "dashboard.tf.login.gov"
  records = ["${aws_route53_record.a_app_tf.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_idv_tf" {
  name = "idv.tf.login.gov"
  records = ["${aws_route53_record.a_app_tf.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_sp_tf" {
  name = "sp.tf.login.gov"
  records = ["${aws_route53_record.a_app_tf.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_sp_python_tf" {
  name = "sp-python.tf.login.gov"
  records = ["${aws_route53_record.a_app_tf.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_sp_rails_tf" {
  name = "sp-rails.tf.login.gov"
  records = ["${aws_route53_record.a_app_tf.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_sp_sinatra_tf" {
  name = "sp-sinatra.tf.login.gov"
  records = ["${aws_route53_record.a_app_tf.name}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}
