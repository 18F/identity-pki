output "pivcac_iam_role_arn" {
  description = "ARN of the PIVCAC IAM role"
  value       = aws_iam_role.pivcac.arn
}

output "pivcac_iam_role_id" {
  description = "ID of the PIVCAC IAM role"
  value       = aws_iam_role.pivcac.id
}

output "base_permissions_iam_role_arn" {
  description = "ARN of the base-permissions IAM role"
  value       = aws_iam_role.base-permissions.arn
}

output "base_permissions_iam_role_id" {
  description = "ID of the base-permissions IAM role"
  value       = aws_iam_role.base-permissions.id
}

output "citadel_client_iam_role_arn" {
  description = "ARN of the citadel-client IAM role"
  value       = aws_iam_role.citadel-client.arn
}

output "citadel_client_iam_role_id" {
  description = "ID of the citadel-client IAM role"
  value       = aws_iam_role.citadel-client.id
}

output "flow_role_iam_role_arn" {
  description = "ARN of the flow_role IAM role"
  value       = aws_iam_role.flow_role.arn
}

output "flow_role_iam_role_id" {
  description = "ID of the flow_role IAM role"
  value       = aws_iam_role.flow_role.id
}

output "service_discovery_iam_role_arn" {
  description = "ARN of the service-discovery IAM role"
  value       = aws_iam_role.service-discovery.arn
}

output "service_discovery_iam_role_id" {
  description = "ID of the service-discovery IAM role"
  value       = aws_iam_role.service-discovery.id
}

output "application_secrets_iam_role_arn" {
  description = "ARN of the application-secrets IAM role"
  value       = aws_iam_role.application-secrets.arn
}

output "application_secrets_iam_role_id" {
  description = "ID of the application-secrets IAM role"
  value       = aws_iam_role.application-secrets.id
}

output "events_log_glue_crawler_iam_role_arn" {
  description = "ARN of the events_log_glue_crawler IAM role"
  value       = aws_iam_role.events_log_glue_crawler.arn
}

output "events_log_glue_crawler_iam_role_id" {
  description = "ID of the events_log_glue_crawler IAM role"
  value       = aws_iam_role.events_log_glue_crawler.id
}

output "migration_iam_role_arn" {
  description = "ARN of the migration IAM role"
  value       = aws_iam_role.migration.arn
}

output "migration_iam_role_id" {
  description = "ID of the migration IAM role"
  value       = aws_iam_role.migration.id
}

output "app_iam_role_arn" {
  description = "ARN of the app IAM role or an empty string if not enabled"
  value       = var.apps_enabled == 1 ? aws_iam_role.app[0].arn : ""
}

output "app_iam_role_id" {
  description = "ID of the app IAM role or an empty string if not enabled"
  value       = var.apps_enabled == 1 ? aws_iam_role.app[0].id : ""
}

output "obproxy_iam_role_arn" {
  description = "ARN of the obproxy IAM role"
  value       = aws_iam_role.obproxy.arn
}

output "obproxy_iam_role_id" {
  description = "ID of the obproxy IAM role"
  value       = aws_iam_role.obproxy.id
}

output "idp_iam_role_arn" {
  description = "ARN of the idp IAM role"
  value       = aws_iam_role.idp.arn
}

output "idp_iam_role_id" {
  description = "ID of the idp IAM role"
  value       = aws_iam_role.idp.id
}

output "worker_iam_role_arn" {
  description = "ARN of the worker IAM role"
  value       = aws_iam_role.worker.arn
}

output "worker_iam_role_id" {
  description = "ID of the worker IAM role"
  value       = aws_iam_role.worker.id
}

output "pivcac_iam_role_name" {
  description = "Name of the PIVCAC IAM role"
  value       = aws_iam_role.pivcac.name
}

output "base_permissions_iam_role_name" {
  description = "Name of the base-permissions IAM role"
  value       = aws_iam_role.base-permissions.name
}

output "citadel_client_iam_role_name" {
  description = "Name of the citadel-client IAM role"
  value       = aws_iam_role.citadel-client.name
}

output "flow_role_iam_role_name" {
  description = "Name of the flow_role IAM role"
  value       = aws_iam_role.flow_role.name
}

output "service_discovery_iam_role_name" {
  description = "Name of the service-discovery IAM role"
  value       = aws_iam_role.service-discovery.name
}

output "application_secrets_iam_role_name" {
  description = "Name of the application-secrets IAM role"
  value       = aws_iam_role.application-secrets.name
}

output "events_log_glue_crawler_iam_role_name" {
  description = "Name of the events_log_glue_crawler IAM role"
  value       = aws_iam_role.events_log_glue_crawler.name
}

output "migration_iam_role_name" {
  description = "Name of the migration IAM role"
  value       = aws_iam_role.migration.name
}

output "app_iam_role_name" {
  description = "Name of the app IAM role or an empty string if not enabled"
  value       = var.apps_enabled == 1 ? aws_iam_role.app[0].name : ""
}

output "obproxy_iam_role_name" {
  description = "Name of the obproxy IAM role"
  value       = aws_iam_role.obproxy.name
}

output "idp_iam_role_name" {
  description = "Name of the idp IAM role"
  value       = aws_iam_role.idp.name
}

output "worker_iam_role_name" {
  description = "Name of the worker IAM role"
  value       = aws_iam_role.worker.name
}

output "assume_role_from_vpc_json" {
  description = "JSON content of the assume_role_from_vpc IAM policy document"
  value       = data.aws_iam_policy_document.assume_role_from_vpc.json
}