resource "aws_route53_record" "worker_external" {
  zone_id = var.route53_id
  name    = "worker.${var.env_name}.${var.root_domain}"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_alb.worker.dns_name]
}

resource "aws_alb" "worker" {
  name            = "${var.name}-worker-alb-${var.env_name}"
  security_groups = [aws_security_group.worker-alb.id]
  subnets         = [for subnet in aws_subnet.public-ingress : subnet.id]

  access_logs {
    bucket  = "login-gov.elb-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
    prefix  = "${var.env_name}/worker"
    enabled = true
  }

  enable_deletion_protection = var.enable_deletion_protection == 1 ? true : false
}

resource "aws_alb_listener" "worker" {
  load_balancer_arn = aws_alb.worker.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.worker.id
    type             = "forward"
  }
}

# Create a TLS certificate with ACM
module "acm-cert-worker" {
  source = "github.com/18F/identity-terraform//acm_certificate?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/acm_certificate"

  domain_name = "worker.${var.env_name}.${var.root_domain}"
  subject_alternative_names = [
    "worker.${var.env_name}.${var.root_domain}",
  ]
  validation_zone_id = var.route53_id
}

resource "aws_alb_listener" "worker_ssl" {
  depends_on = [module.acm-cert-worker.finished_id] # don't use cert until valid

  certificate_arn   = module.acm-cert-worker.cert_arn
  load_balancer_arn = aws_alb.worker.id
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"

  default_action {
    target_group_arn = aws_alb_target_group.worker_ssl.id
    type             = "forward"
  }
}

resource "aws_alb_target_group" "worker" {
  depends_on = [aws_alb.worker]

  health_check {
    matcher = "301"
  }

  name     = "${var.env_name}-worker-http"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.default.id

  deregistration_delay = 120
}

resource "aws_alb_target_group" "worker_ssl" {
  depends_on = [aws_alb.worker]

  health_check {
    matcher  = "200"
    protocol = "HTTPS"

    interval            = 10
    timeout             = 5
    healthy_threshold   = 9 # up for 90 seconds
    unhealthy_threshold = 2 # down for 20 seconds
  }

  name     = "${var.env_name}-worker-ssl"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = aws_vpc.default.id

  deregistration_delay = 120

  tags = {
    prefix      = var.env_name
    health_role = "worker"
  }
}
