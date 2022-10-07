output "rds_parameter_group_name" {
  value = length(var.pgroup_params) > 0 ? aws_db_parameter_group.force_ssl[0].name : null
}