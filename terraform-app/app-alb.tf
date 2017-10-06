resource "aws_alb" "app" {
  count = "${var.alb_enabled * var.apps_enabled}"
  name = "${var.name}-app-alb-${var.env_name}"
  security_groups = ["${aws_security_group.web.id}"]
  subnets = ["${aws_subnet.alb1.id}", "${aws_subnet.alb2.id}"]

  access_logs = {
    bucket = "login-gov.elb-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
    prefix = "${var.env_name}/app"
  }

  enable_deletion_protection = "${var.enable_deletion_protection}"
}

resource "aws_alb_listener" "app" {
  count = "${var.alb_enabled * var.apps_enabled}"
  load_balancer_arn = "${aws_alb.app.id}"
  port = "80"
  protocol = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.app.id}"
    type = "forward"
  }
}

# This cert should be created by hand with these names:
# sp.env.login.gov
# dashboard.env.login.gov
# sp-oidc-sinatra.env.login.gov
# sp-rails.env.login.gov
# sp-sinatra.env.login.gov
# app.env.login.gov
# apps.env.login.gov
#
# https://us-west-2.console.aws.amazon.com/acm/home?region=us-west-2#/
#
data "aws_acm_certificate" "apps-combined" {
    domain = "sp.${var.env_name}.${var.root_domain}"
    statuses = ["ISSUED"]
}

resource "aws_alb_listener" "app-ssl" {
  count = "${var.alb_enabled * var.apps_enabled}"
  certificate_arn = "${data.aws_acm_certificate.apps-combined.arn}"
  load_balancer_arn = "${aws_alb.app.id}"
  port = "443"
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2015-05"

  default_action {
    target_group_arn = "${aws_alb_target_group.app-ssl.id}"
    type             = "forward"
  }
}

resource "aws_alb_target_group" "app" {
  count = "${var.alb_enabled * var.apps_enabled}"
  depends_on = ["aws_alb.app"]

  health_check {
    matcher =  "301"
  }

  name = "${var.env_name}-app-http"
  port = 80
  protocol = "HTTP"
  vpc_id = "${aws_vpc.default.id}"

  deregistration_delay = 120
}

resource "aws_alb_target_group" "app-ssl" {
  count = "${var.alb_enabled * var.apps_enabled}"
  depends_on = ["aws_alb.app"]

  health_check {
    # we don't actually have basic auth enabled on app
    #matcher =  "${var.basic_auth_enabled ? 401 : 200}"
    matcher =  "200"
    protocol = "HTTPS"

    interval = 10
    timeout = 5
    healthy_threshold = 9 # up for 90 seconds
    unhealthy_threshold = 2 # down for 20 seconds
  }

  name = "${var.env_name}-app-ssl"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = "${aws_vpc.default.id}"

  deregistration_delay = 120
}
