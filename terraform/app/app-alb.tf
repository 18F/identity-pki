resource "aws_alb" "app" {
  count           = var.apps_enabled
  name            = "${var.name}-app-alb-${var.env_name}"
  security_groups = [aws_security_group.app-alb[count.index].id]
  subnets         = [for subnet in aws_subnet.public-ingress : subnet.id]

  enable_tls_version_and_cipher_suite_headers = var.enable_tls_and_cipher_headers

  access_logs {
    bucket  = "login-gov.elb-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
    prefix  = "${var.env_name}/app"
    enabled = true
  }

  enable_deletion_protection = var.enable_deletion_protection == 1 ? true : false
}

resource "aws_alb_listener" "app" {
  count             = var.apps_enabled * var.alb_http_port_80_enabled
  load_balancer_arn = aws_alb.app[0].id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.app[0].id
    type             = "forward"
  }
}

locals {

  app_domain_name = "sp.${var.env_name}.${var.root_domain}"
  app_alternative_names = [
    "app.${var.env_name}.${var.root_domain}",
    "dashboard.${var.env_name}.${var.root_domain}",
  ]

}


# Create a TLS certificate with ACM
module "acm-cert-apps-combined" {
  count  = var.apps_enabled
  source = "github.com/18F/identity-terraform//acm_certificate?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/acm_certificate"

  domain_name               = local.app_domain_name
  subject_alternative_names = local.app_alternative_names
  validation_zone_id        = var.route53_id
}

resource "aws_alb_listener" "app-ssl" {
  depends_on = [module.acm-cert-apps-combined[0].finished_id] # don't use cert until valid

  count             = var.apps_enabled
  certificate_arn   = module.acm-cert-apps-combined[0].cert_arn
  load_balancer_arn = aws_alb.app[0].id
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-FIPS-2023-04"

  default_action {
    type = "redirect"

    redirect {
      host        = local.app_domain_name
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener_rule" "app_ssl" {
  count        = var.apps_enabled
  listener_arn = aws_alb_listener.app-ssl[0].arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.app-ssl[0].arn
  }
  condition {
    http_header {
      http_header_name = local.cloudfront_security_header.name
      values           = local.cloudfront_security_header.value
    }
  }
}

resource "aws_alb_target_group" "app" {
  count      = var.apps_enabled
  depends_on = [aws_alb.app]

  health_check {
    matcher = "301"
  }

  name     = "${var.env_name}-app-http"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.network_uw2.vpc_id

  deregistration_delay = 120
}

resource "aws_alb_target_group" "app-ssl" {
  count      = var.apps_enabled
  depends_on = [aws_alb.app]

  health_check {
    matcher  = "200"
    protocol = "HTTPS"

    interval            = 10
    timeout             = 5
    healthy_threshold   = 9 # up for 90 seconds
    unhealthy_threshold = 2 # down for 20 seconds
  }

  name     = "${var.env_name}-app-ssl"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = module.network_uw2.vpc_id

  deregistration_delay = 120

  tags = {
    prefix      = var.env_name
    health_role = "app"
  }
}

