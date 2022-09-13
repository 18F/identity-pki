resource "aws_lb" "gitlab" {
  name    = "${var.env_name}-gitlab"
  subnets = [for zone in local.network_zones : aws_subnet.public-ingress[zone].id]

  load_balancer_type = "network"

  access_logs {
    bucket  = "login-gov.elb-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
    prefix  = "${var.env_name}/gitlab"
    enabled = true
  }

  tags = {
    Name           = "${var.env_name}-gitlab"
    "s3:x-amz-acl" = "bucket-owner-full-control"
  }
}

# If we want to use WAF rules, ensure we have a WAF ACL
data "aws_wafv2_web_acl" "alb-acl" {
  count = var.use_waf_rules ? 1 : 0
  name  = "${aws_lb.gitlab-waf.name}-waf"
  scope = "REGIONAL"
}

resource "aws_lb" "gitlab-waf" {
  name = "${var.env_name}-gitlab-waf"
  security_groups = [
    aws_security_group.waf_alb.id,
    aws_security_group.base.id,
  ]
  internal = true
  subnets  = [for zone in local.network_zones : aws_subnet.apps[zone].id]

  load_balancer_type = "application"

  access_logs {
    bucket  = "login-gov.elb-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
    prefix  = "${var.env_name}/gitlab-waf"
    enabled = true
  }

  tags = {
    Name = "${var.env_name}-gitlab"
  }
}

resource "aws_lb_target_group" "gitlab" {
  name     = "${var.env_name}-gitlab"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = aws_vpc.default.id
  health_check {
    protocol = "HTTPS"
    matcher  = "200,302"
  }
}

resource "aws_lb_target_group" "gitlab-ssh" {
  name     = "${var.env_name}-gitlab-ssh"
  port     = 22
  protocol = "TCP"
  vpc_id   = aws_vpc.default.id
}

resource "aws_lb_target_group" "gitlab-waf" {
  name        = "${var.env_name}-gitlab-waf"
  target_type = "alb"
  port        = 443
  protocol    = "TCP"
  vpc_id      = aws_vpc.default.id
  health_check {
    protocol = "HTTPS"
  }
}

resource "aws_lb_target_group_attachment" "waf" {
  target_group_arn = aws_lb_target_group.gitlab-waf.arn
  target_id        = aws_lb.gitlab-waf.arn
}

resource "aws_lb_listener" "gitlab-to-gitlab-waf" {
  load_balancer_arn = aws_lb.gitlab.arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gitlab-waf.arn
  }
}

resource "aws_lb_listener" "gitlab-waf-to-instances" {
  load_balancer_arn = aws_lb.gitlab-waf.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.gitlab.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gitlab.arn
  }
}

resource "aws_lb_listener" "gitlab-ssh" {
  load_balancer_arn = aws_lb.gitlab.arn
  port              = "22"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gitlab-ssh.arn
  }
}

resource "aws_route53_record" "gitlab-elb-public" {
  zone_id = var.route53_id
  name    = "gitlab.${var.env_name}"
  type    = "A"
  alias {
    name                   = aws_lb.gitlab.dns_name
    zone_id                = aws_lb.gitlab.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "gitlab-elb-private" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "gitlab.${var.env_name}.${var.root_domain}"
  type    = "A"
  alias {
    name                   = aws_lb.gitlab.dns_name
    zone_id                = aws_lb.gitlab.zone_id
    evaluate_target_health = true
  }
}

# This is only for production, where we want "gitlab.login.gov" to work.
resource "aws_route53_record" "gitlab-elb-public-production" {
  count   = var.production ? 1 : 0
  zone_id = var.route53_id
  name    = ""
  type    = "A"
  alias {
    name                   = aws_lb.gitlab.dns_name
    zone_id                = aws_lb.gitlab.zone_id
    evaluate_target_health = true
  }
}
