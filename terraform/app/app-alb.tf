resource "aws_alb" "app" {
  count           = var.apps_enabled
  name            = "${var.name}-app-alb-${var.env_name}"
  security_groups = [aws_security_group.app-alb[count.index].id]
  subnets         = [for subnet in aws_subnet.public-ingress : subnet.id]

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

# Create a TLS certificate with ACM
module "acm-cert-apps-combined" {
  count  = var.apps_enabled
  source = "github.com/18F/identity-terraform//acm_certificate?ref=e7ad5ef38f724b31911248a74173e9fee3bbf045"
  #source = "../../../identity-terraform/acm_certificate"

  domain_name = "sp.${var.env_name}.${var.root_domain}"
  subject_alternative_names = [
    "app.${var.env_name}.${var.root_domain}",
    "apps.${var.env_name}.${var.root_domain}",
    "dashboard.${var.env_name}.${var.root_domain}",
    "sp-oidc-sinatra.${var.env_name}.${var.root_domain}",
    "sp-rails.${var.env_name}.${var.root_domain}",
    "sp-sinatra.${var.env_name}.${var.root_domain}",
  ]
  validation_zone_id = var.route53_id
}

resource "aws_alb_listener" "app-ssl" {
  depends_on = [module.acm-cert-apps-combined[0].finished_id] # don't use cert until valid

  count             = var.apps_enabled
  certificate_arn   = module.acm-cert-apps-combined[0].cert_arn
  load_balancer_arn = aws_alb.app[0].id
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"

  default_action {
    target_group_arn = aws_alb_target_group.app-ssl[0].id
    type             = "forward"
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
  vpc_id   = aws_vpc.default.id

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
  vpc_id   = aws_vpc.default.id

  deregistration_delay = 120

  tags = {
    prefix      = var.env_name
    health_role = "app"
  }
}

