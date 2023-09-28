resource "aws_athena_database" "logs_database" {
  name   = "${var.env_name}_logs"
  bucket = aws_s3_bucket.athena_query_results.bucket

  encryption_configuration {
    encryption_option = "SSE_S3"
  }
}

output "database" {
  value = aws_athena_database.logs_database
}
