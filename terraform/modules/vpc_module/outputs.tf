output "vpc_id" {
  value = aws_vpc.default.id
}

output "secondary_cidr" {
  value = var.secondary_cidr_block
}

output "ipv6_cidr_block" {
  value = aws_vpc.default.ipv6_cidr_block
}

output "s3_prefix_list_id" {
  value = aws_vpc_endpoint.private-s3.prefix_list_id
}

output "db_security_group" {
  value = aws_security_group.db.id
}

output "db_subnet_group" {
  value = aws_db_subnet_group.aurora.id
}

output "db_subnet_ids" {
  value = aws_db_subnet_group.aurora.subnet_ids
}

output "app_security_group" {
  value = aws_security_group.app[0].id
}

output "db_subnet" {
  description = "Data-services subnets"
  value       = aws_subnet.data-services
}

output "app_subnet" {
  description = "App services subnets"
  value       = aws_subnet.app
}

output "base_id" {
  value = aws_security_group.base.id
}

output "endpoint_sg" {
  value = { for k, v in aws_security_group.endpoint : k => v.id }
}

output "security_group_id" {
  value = module.outboundproxy_net.security_group_id
}

output "migration_sg_id" {
  value = aws_security_group.migration.id
}

output "app_alb_sg_id" {
  value = aws_security_group.app-alb[0].id
}
