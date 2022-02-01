output "proxy_security_group_id" {
  value = aws_security_group.gitlab_runner.id
}

output "proxy_asg_id" {
  value = aws_autoscaling_group.gitlab_runner.id
}
