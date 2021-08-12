resource "aws_elb" "gitlab" {
  name = "${var.env_name}-gitlab"
  subnets = [
    aws_subnet.gitlab1.id,
    aws_subnet.gitlab2.id,
  ]

  # TODO move the gitlab ELB to its own security group
  security_groups = [aws_security_group.gitlab.id]

  access_logs {
    bucket        = "login-gov.elb-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
    bucket_prefix = "${var.env_name}/gitlab"
    interval      = 5
  }

  listener {
    instance_port     = 22
    instance_protocol = "tcp"
    lb_port           = 22
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    target              = "TCP:26"
    interval            = 15
  }

  internal            = false
  idle_timeout        = 900
  connection_draining = true

  tags = {
    Name = "${var.env_name}-gitlab"
  }
}

resource "aws_route53_record" "gitlab-elb-internal" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "gitlab"
  type    = "A"
  alias {
    name                   = aws_elb.gitlab.dns_name
    zone_id                = aws_elb.gitlab.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "gitlab-elb-public" {
  zone_id = var.route53_id
  name    = "gitlab.${var.env_name}"
  type    = "A"
  alias {
    name                   = aws_elb.gitlab.dns_name
    zone_id                = aws_elb.gitlab.zone_id
    evaluate_target_health = true
  }
}
