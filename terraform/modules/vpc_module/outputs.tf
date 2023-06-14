output "vpc_id" {
  value = data.aws_vpc.default_vpc.id
}

output "secondary_cidr" {
  value = data.aws_vpc.default_vpc.cidr_block_associations[0].cidr_block
}

output "db_security_group" {
  value = var.enable_data_services ? aws_security_group.db[*].id : null
}

output "db_nacl" {
  value = var.enable_data_services ? aws_network_acl.db[*].id : null
}

output "app_security_group" {
  value = var.enable_app ? aws_security_group.app[*].id : null
}

output "app_nacl" {
  value = var.enable_app ? aws_network_acl.idp[*].id : null
}

output "db_subnet_cidr_blocks" {
  description = "List of cidr_blocks of data-services subnets"
  value       = var.enable_data_services ? [for s in data.aws_subnet.db_subnets : s.cidr_block] : null
}

output "db_subnet_ids" {
  description = "List of IDs of data-services subnets"
  value       = var.enable_data_services ? [for s in data.aws_subnet.db_subnets : s.id] : null
}

output "app_subnet_cidr_blocks" {
  description = "List of cidr_blocks of App services subnets"
  value       = var.enable_app ? [for s in data.aws_subnet.app : s.cidr_block] : null
}

output "app_subnet_ids" {
  description = "List of IDs of App services subnets"
  value       = var.enable_app ? [for s in data.aws_subnet.app : s.id] : null
}