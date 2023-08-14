output "proxy_lb_cidr_blocks" {
  value = formatlist("%s/32", data.aws_network_interface.obproxy.*.private_ip)
}

output "proxy_asg_name" {
  value = aws_autoscaling_group.outboundproxy.name
}

output "proxy_instance_profile" {
  value = var.external_instance_profile == "" ? aws_iam_instance_profile.obproxy[0].name : null
}