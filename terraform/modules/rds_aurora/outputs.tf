output "kms_arn" {
  value = data.aws_kms_key.rds_alias.arn
}

output "cluster_id" {
  value = aws_rds_cluster.aurora.id
}

output "cluster_arn" {
  value = aws_rds_cluster.aurora.arn
}

output "global_cluster_id" {
  value = var.create_global_db ? aws_rds_global_cluster.aurora[0].id : null
}

output "global_cluster_arn" {
  value = var.create_global_db ? aws_rds_global_cluster.aurora[0].arn : null
}

output "writer_instance" {
  value = one([
    for num in range(
      0, var.primary_cluster_instances
    ) : aws_rds_cluster_instance.aurora[num].id if aws_rds_cluster_instance.aurora[num].writer
  ])
}

output "reader_instances" {
  value = [
    for num in range(
      0, var.primary_cluster_instances
    ) : aws_rds_cluster_instance.aurora[num].id if !aws_rds_cluster_instance.aurora[num].writer
  ]
}

output "writer_endpoint" {
  value = aws_rds_cluster.aurora.endpoint
}

output "writer_instance_endpoint" {
  value = aws_rds_cluster_instance.aurora[0].endpoint
}

output "writer_instance_az" {
  value = aws_rds_cluster_instance.aurora[0].availability_zone
}

output "reader_endpoint" {
  value = aws_rds_cluster.aurora.reader_endpoint
}
