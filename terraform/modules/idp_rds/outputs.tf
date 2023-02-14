output "rds_parameter_group" {
  value = length(var.pgroup_params) > 0 ? aws_db_parameter_group.force_ssl[0].name : null
}

output "aurora_cluster_pgroup" {
  value = length(var.cluster_pgroup_params) > 0 ? aws_rds_cluster_parameter_group.aurora[0].name : null
}

output "aurora_db_pgroup" {
  value = length(var.db_pgroup_params) > 0 ? aws_db_parameter_group.aurora[0].name : null
}

output "rds_kms_key_arn" {
  value = aws_kms_key.idp_rds.arn
}
