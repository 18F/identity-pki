resource "aws_lb" "elasticsearch" {
  name               = "${var.env_name}-elasticsearch-lb"
  internal           = true
  load_balancer_type = "network"
  subnets            = ["${aws_subnet.elasticsearch.*.id}"]

  access_logs {
    bucket        = "login-gov.elasticsearch-lb-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
    prefix = "${var.env_name}/elasticsearch"
    enabled      = true
  }

  tags {
    Name = "elasticsearch-lb"
  }
}

resource "aws_lb_listener" "elasticsearch" {
  default_action {
    target_group_arn = "${aws_lb_target_group.elasticsearch.arn}"
    type             = "forward"
  }

  load_balancer_arn = "${aws_lb.elasticsearch.arn}"
  port = 9200
  protocol = "TCP"
}

resource "aws_lb_target_group" "elasticsearch" {
  name               = "${var.env_name}-elasticsearch-target-group"
  port = 9200
  protocol = "TCP"
  target_type = "instance"
  vpc_id = "${aws_vpc.default.id}"

  health_check {
    healthy_threshold   = 2
    interval            = 30
    protocol            = "TCP"
    unhealthy_threshold = 2
  }
}

resource "aws_route53_record" "elasticsearch" {
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name = "elasticsearch.login.gov.internal"
  ttl = "300"
  type = "CNAME"
  records = ["${aws_lb.elasticsearch.dns_name}"]
}
