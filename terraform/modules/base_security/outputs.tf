output "base_id" {
  value = aws_security_group.base.id
}

output "endpoint_sg" {
  value = { for k, v in aws_security_group.endpoint : k => v.id }
}