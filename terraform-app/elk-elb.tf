resource "aws_elb" "elk" {
  name            = "${var.env_name}-elk"
  subnets         = aws_subnet.elk.*.id
  security_groups = [aws_security_group.elk.id]

  access_logs {
    bucket        = "login-gov.elb-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
    bucket_prefix = "${var.env_name}/elk"
    interval      = 5
  }

  listener {
    instance_port     = 8443
    instance_protocol = "tcp"
    lb_port           = 8443
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 5044
    instance_protocol = "tcp"
    lb_port           = 5044
    lb_protocol       = "tcp"
  }

  # TODO: Make this an ALB with target groups, so we can do real health checks.
  # TODO: Make separate ALBs for logstash and kibana with their own health
  # checks.
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:5044"
    interval            = 5
  }

  internal                  = true
  cross_zone_load_balancing = true

  tags = {
    Name   = "elk-internal-elb"
    client = var.client
  }
}

resource "aws_route53_record" "kibana" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "kibana.login.gov.internal"
  ttl     = "300"
  type    = "CNAME"
  records = [aws_elb.elk.dns_name]
}

resource "aws_route53_record" "logstash" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "logstash.login.gov.internal"
  ttl     = "300"
  type    = "CNAME"
  records = [aws_elb.elk.dns_name]
}

