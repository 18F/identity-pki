resource "aws_lb" "gitlab" {
  name_prefix = substr("${var.env_name}-gitlab", 0, 6)
  subnets = [
    aws_subnet.publicsubnet1.id,
    aws_subnet.publicsubnet2.id,
    aws_subnet.publicsubnet3.id
  ]

  load_balancer_type = "network"

  access_logs {
    bucket  = "login-gov.elb-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
    prefix  = "${var.env_name}/gitlab"
    enabled = true
  }

  tags = {
    Name = "${var.env_name}-gitlab"
  }
}

resource "aws_lb_target_group" "gitlab" {
  name     = "${var.env_name}-gitlab"
  port     = 443
  protocol = "TLS"
  vpc_id   = aws_vpc.default.id
}

resource "aws_lb_target_group" "gitlab-ssh" {
  name     = "${var.env_name}-gitlab-ssh"
  port     = 22
  protocol = "TCP"
  vpc_id   = aws_vpc.default.id
}

resource "aws_lb_listener" "gitlab" {
  load_balancer_arn = aws_lb.gitlab.arn
  port              = "443"
  protocol          = "TLS"
  certificate_arn   = aws_acm_certificate.gitlab.arn
  alpn_policy       = "HTTP2Preferred"

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
