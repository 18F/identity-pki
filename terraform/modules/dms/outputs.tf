output "dms_replication_instance_arn" {
  value = aws_dms_replication_instance.dms.replication_instance_arn
}

output "dms_source_endpoint_arn" {
  value = aws_dms_endpoint.aurora_source.endpoint_arn
}

output "dms_target_endpoint_arn" {
  value = aws_dms_endpoint.aurora_target.endpoint_arn
}
