output "vpc_id" {
  value = aws_vpc.default.id
}

output "secondary_cidr" {
  value = var.secondary_cidr_block
}

output "s3_prefix_list_id" {
  value = aws_vpc_endpoint.private-s3[0].prefix_list_id
}

output "db_security_group" {
  value = var.enable_data_services ? aws_security_group.db[*].id : null
}

output "app_security_group" {
  value = var.enable_app ? aws_security_group.app[*].id : null
}

output "db_subnet_ids" {
  description = "List of IDs of data-services subnets"
  value       = var.enable_data_services ? [for s in aws_subnet.data-services : s.id] : null
}

output "app_subnet_ids" {
  description = "List of IDs of App services subnets"
  value       = var.enable_app ? [for s in aws_subnet.app : s.id] : null
}