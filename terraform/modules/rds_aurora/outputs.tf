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