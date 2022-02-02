output "proxy_security_group_id" {
  value = aws_security_group.obproxy.id
}

output "proxy_asg_name" {
  value = aws_autoscaling_group.outboundproxy.name
}
