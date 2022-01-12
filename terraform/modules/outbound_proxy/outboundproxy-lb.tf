resource "aws_lb" "obproxy" {
  name                             = "${var.env_name}-obproxy"
  internal                         = true
  load_balancer_type               = "network"
  subnets                          = var.public_subnets
  enable_cross_zone_load_balancing = true

  tags = {
    Name   = "${var.env_name}-obproxy"
    prefix = "obproxy"
    domain = "${var.env_name}.${var.root_domain}"
  }
}

resource "aws_lb_listener" "obproxy" {
  depends_on        = [aws_lb.obproxy]
  load_balancer_arn = aws_lb.obproxy.arn
  port              = "3128"
  protocol          = "TCP"
  default_action {
    target_group_arn = aws_lb_target_group.obproxy.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "obproxy" {
  depends_on = [aws_lb.obproxy]
  name       = "${var.env_name}-obproxy2-target"
  port       = 3128
  protocol   = "TCP"
  vpc_id     = var.vpc_id

  deregistration_delay = 120

  tags = {
    prefix      = var.env_name
    health_role = "outboundproxy"
  }
}
