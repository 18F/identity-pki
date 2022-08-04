resource "aws_athena_database" "logs_database" {
  name   = var.database_name
  bucket = var.bucket_name

  encryption_configuration{
    encryption_option = "SSE_KMS"
    kms_key = var.kms_key
  }
}

output "database"{
  value = aws_athena_database.logs_database
}