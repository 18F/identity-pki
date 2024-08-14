resource "aws_lb" "analytics" {
  name = "${var.env_name}-analytics"
  security_groups = [
    aws_security_group.analytics_alb.id,
    aws_security_group.base.id,
  ]
  internal                   = true
  subnets                    = [for zone in local.network_zones : aws_subnet.apps[zone].id]
  drop_invalid_header_fields = true

  load_balancer_type = "application"

  access_logs {
    bucket  = "login-gov.elb-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
    prefix  = "${var.env_name}/analytics"
    enabled = true
  }

  tags = {
    Name = "${var.env_name}-analytics"
  }
}

resource "aws_lb_target_group" "analytics" {
  name     = "${var.env_name}-analytics"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = aws_vpc.analytics_vpc.id
  health_check {
    protocol = "HTTPS"
    matcher  = "200,302"
  }
}
