# TODO: remove all of the outboundproxy variants in favor of obproxy copy below
resource "aws_lb" "outboundproxy" {
    name               = "${var.env_name}-outboundproxy"
    internal           = true
    load_balancer_type = "network"
    subnets            = ["${aws_subnet.privatesubnet1.id}", "${aws_subnet.privatesubnet2.id}", "${aws_subnet.privatesubnet3.id}"]
    enable_cross_zone_load_balancing = true

  tags {
    Name = "${var.env_name}-outboundproxy"
    prefix = "outboundproxy"
    domain = "${var.env_name}.${var.root_domain}"
  }
}

# TODO remove
resource "aws_lb_listener" "outboundproxy" {
  depends_on = ["aws_lb.outboundproxy"]
  load_balancer_arn = "${aws_lb.outboundproxy.arn}"
  port              = "3128"
  protocol          = "TCP"
  default_action {
    target_group_arn = "${aws_lb_target_group.outboundproxy.arn}"
    type             = "forward"
  }
}

# TODO remove
resource "aws_lb_target_group" "outboundproxy" {
  depends_on = ["aws_lb.outboundproxy"]
  name = "${var.env_name}-obproxy-target"
  port = 3128
  protocol = "TCP"
  vpc_id = "${aws_vpc.default.id}"

  deregistration_delay = 120
}

# -- duplicate copy used for migrating to public subnets --

resource "aws_lb" "obproxy" {
  name               = "${var.env_name}-obproxy"
  internal           = true
  load_balancer_type = "network"
  subnets            = ["${aws_subnet.publicsubnet1.id}", "${aws_subnet.publicsubnet2.id}", "${aws_subnet.publicsubnet3.id}"]
  enable_cross_zone_load_balancing = true

  tags {
    Name = "${var.env_name}-obproxy"
    prefix = "obproxy"
    domain = "${var.env_name}.${var.root_domain}"
  }
}

resource "aws_lb_listener" "obproxy" {
  depends_on = ["aws_lb.obproxy"]
  load_balancer_arn = "${aws_lb.obproxy.arn}"
  port              = "3128"
  protocol          = "TCP"
  default_action {
    target_group_arn = "${aws_lb_target_group.obproxy.arn}"
    type             = "forward"
  }
}

resource "aws_lb_target_group" "obproxy" {
  depends_on = ["aws_lb.obproxy"]
  name = "${var.env_name}-obproxy2-target"
  port = 3128
  protocol = "TCP"
  vpc_id = "${aws_vpc.default.id}"

  deregistration_delay = 120
}
