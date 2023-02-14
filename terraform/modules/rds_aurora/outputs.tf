output "cluster_id" {
  value = aws_rds_cluster.aurora.id
}

output "writer_instance" {
  value = aws_rds_cluster_instance.aurora[0].id
}

output "reader_instances" {
  value = var.primary_cluster_instances == 1 ? [] : [
    for num in range(
      1, var.primary_cluster_instances
    ) : aws_rds_cluster_instance.aurora[num].id
  ]
}

output "writer_endpoint" {
  value = aws_rds_cluster.aurora.endpoint
}

output "writer_fqdn" {
  value = aws_route53_record.writer_endpoint.fqdn
}

output "writer_instance_endpoint" {
  value = aws_rds_cluster_instance.aurora[0].endpoint
}

output "reader_endpoint" {
  value = aws_rds_cluster.aurora.reader_endpoint
}

output "reader_fqdn" {
  value = aws_route53_record.reader_endpoint.fqdn
}

output "cluster_pgroup" {
  value = var.custom_apg_cluster_pgroup == "" ? (
  aws_rds_cluster_parameter_group.aurora[0].name) : null
}

output "instance_pgroup" {
  value = var.custom_apg_db_pgroup == "" && var.major_upgrades ? (
  aws_db_parameter_group.aurora[0].name) : null
}

output "primary_instance" {
  value = aws_rds_cluster_instance.aurora[0]
}
