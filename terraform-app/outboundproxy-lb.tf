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

resource "aws_lb_target_group" "outboundproxy" {
  depends_on = ["aws_lb.outboundproxy"]
  name = "${var.env_name}-obproxy-target"
  port = 3128
  protocol = "TCP"
  vpc_id = "${aws_vpc.default.id}"

  deregistration_delay = 120
}