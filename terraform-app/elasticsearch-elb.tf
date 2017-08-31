resource "aws_elb" "elasticsearch" {
  name               = "${var.env_name}-elasticsearch"
  subnets = ["${aws_subnet.elasticsearch.*.id}"]
  security_groups = ["${aws_security_group.elk.id}"]

  access_logs {
    bucket        = "login-gov.elb-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
    bucket_prefix = "${var.env_name}/elasticsearch"
    interval      = 5
  }

  listener {
    instance_port     = 9200
    instance_protocol = "tcp"
    lb_port           = 9200
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTPS:9200/_cluster/health"
    interval            = 5
  }

  internal = true
  cross_zone_load_balancing   = true

  tags {
    Name = "elasticsearch-internal-elb"
    client = "${var.client}"
  }
}

resource "aws_route53_record" "elasticsearch" {
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name = "elasticsearch.login.gov.internal"
  ttl = "300"
  type = "CNAME"
  records = ["${aws_elb.elasticsearch.dns_name}"]
}
