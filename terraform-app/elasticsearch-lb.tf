resource "aws_lb" "elasticsearch" {
  name               = "${var.env_name}-elasticsearch-lb"
  internal           = true
  load_balancer_type = "network"
  subnets            = aws_subnet.elasticsearch.*.id

  # Access logs are not enabled because AWS only emits them when there is a TLS
  # listener, which we don't have.
  # https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-access-logs.html
  #
  # > Access logs are created only if the load balancer has a TLS listener and
  # > they contain information only about TLS requests.
  #
  # NLBs also require different permissions from ELB or ALB for log delivery,
  # so we would need to modify the permissions on elb-logs or use a different
  # bucket.
  #
  #access_logs {
  #  bucket = "login-gov.elb-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
  #  prefix = "${var.env_name}/elasticsearch"
  #  enabled = false
  #}

  tags = {
    Name = "elasticsearch-lb"
  }
}

resource "aws_lb_listener" "elasticsearch" {
  default_action {
    target_group_arn = aws_lb_target_group.elasticsearch.arn
    type             = "forward"
  }

  load_balancer_arn = aws_lb.elasticsearch.arn
  port              = 9200
  protocol          = "TCP"
}

resource "aws_lb_target_group" "elasticsearch" {
  name        = "${var.env_name}-es-target-group"
  port        = 9200
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = aws_vpc.default.id

  health_check {
    healthy_threshold   = 2
    interval            = 30
    protocol            = "TCP"
    unhealthy_threshold = 2
  }

  tags = {
    prefix      = var.env_name
    health_role = "elasticsearch"
  }
}

resource "aws_route53_record" "elasticsearch" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "elasticsearch.login.gov.internal"
  ttl     = "300"
  type    = "CNAME"
  records = [aws_lb.elasticsearch.dns_name]
}

