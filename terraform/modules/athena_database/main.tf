resource "aws_athena_database" "logs_database" {
  name   = var.database_name
  bucket = var.bucket_name
}

output "database"{
  value = aws_athena_database.logs_database
}