resource "aws_alb" "idp" {
  name = "${var.name}-idp-alb-${var.env_name}"
  security_groups = ["${aws_security_group.web.id}"]
  subnets = ["${aws_subnet.idp1.id}", "${aws_subnet.idp2.id}"]
}

resource "aws_alb_listener" "idp" {
  depends_on = ["aws_alb.idp"]
  load_balancer_arn = "${aws_alb.idp.id}"
  port = "80"
  protocol = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.idp.id}"
    type = "forward"
  }
}

resource "aws_alb_listener" "idp-ssl" {
  certificate_arn = "${aws_iam_server_certificate.idp.arn}"
  load_balancer_arn = "${aws_alb.idp.id}"
  port = "443"
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2015-05"

  default_action {
    target_group_arn = "${aws_alb_target_group.idp-ssl.id}"
    type             = "forward"
  }
}

resource "aws_alb_target_group" "idp" {
  depends_on = ["aws_alb.idp"]
  name = "${var.env_name}-target-group"
  port = 80
  protocol = "HTTP"
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_alb_target_group" "idp-ssl" {
  depends_on = ["aws_alb.idp"]
  name = "${var.env_name}-ssl-target-group"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = "${aws_vpc.default.id}"
}

resource "aws_alb_target_group_attachment" "idp" {
  depends_on = ["aws_alb.idp"]
  port = 80
  target_group_arn = "${aws_alb_target_group.idp.arn}"
  target_id = "${aws_instance.idp.id}"
}

resource "aws_alb_target_group_attachment" "idp-ssl" {
  port = 443
  target_group_arn = "${aws_alb_target_group.idp-ssl.arn}"
  target_id = "${aws_instance.idp.id}"
}

resource "aws_iam_server_certificate" "idp" {
  certificate_body = "${file("${path.cwd}/../certs/${var.env_name}-cert.pem")}"
  certificate_chain = "${file("${path.cwd}/../certs/${var.env_name}-chain.pem")}"
  name = "${var.name}-idp-cert-${var.env_name}"
  private_key = "${file("${path.cwd}/../certs/${var.env_name}-key.pem")}"
}
