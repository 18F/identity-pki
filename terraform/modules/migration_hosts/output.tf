output "migration_asg_name" {
  value = aws_autoscaling_group.migration.name
}

output "migration_sg_id" {
  value = aws_security_group.migration.id
}