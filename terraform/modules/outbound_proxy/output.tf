output "proxy_lb_cidr_blocks" {
  value = formatlist("%s/32", data.aws_network_interface.obproxy.*.private_ip)
}

output "proxy_asg_name" {
  value = aws_autoscaling_group.outboundproxy.name
}
