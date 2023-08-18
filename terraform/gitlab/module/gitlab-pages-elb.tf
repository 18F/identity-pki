resource "aws_lb" "gitlab-pages" {
  name = "${var.env_name}-gitlab-pages"
  security_groups = [
    aws_security_group.pages_alb.id,
  ]
  internal = false
  subnets  = [for zone in local.network_zones : aws_subnet.apps[zone].id]

  load_balancer_type = "application"

  access_logs {
    bucket  = "login-gov.elb-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
    prefix  = "${var.env_name}/gitlab-pages"
    enabled = true
  }

  tags = {
    Name = "${var.env_name}-gitlab-pages"
  }
}

resource "aws_lb_target_group" "gitlab-pages" {
  name        = "${var.env_name}-gitlab-pages"
  target_type = "alb"
  port        = 443
  protocol    = "TCP"
  vpc_id      = aws_vpc.default.id
  health_check {
    protocol = "HTTPS"
  }
}

resource "aws_lb_target_group_attachment" "pages" {
  target_group_arn = aws_lb_target_group.gitlab-pages.arn
  target_id        = aws_lb.gitlab-pages.arn
  port             = 4443
}

resource "aws_lb_listener" "gitlab-pages" {
  load_balancer_arn = aws_lb.gitlab-pages.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-FS-1-2-Res-2020-10"
  certificate_arn   = aws_acm_certificate.gitlab-pages.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gitlab-pages.arn
  }
}

resource "aws_route53_record" "gitlab-pages-public" {
  zone_id = var.route53_id
  name    = "pages.${var.env_name}"
  type    = "A"
  alias {
    name                   = aws_lb.gitlab.dns_name
    zone_id                = aws_lb.gitlab.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "gitlab-pages-private" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "pages.${var.env_name}.${var.root_domain}"
  type    = "A"
  alias {
    name                   = aws_lb.gitlab.dns_name
    zone_id                = aws_lb.gitlab.zone_id
    evaluate_target_health = true
  }
}
