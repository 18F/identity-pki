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

resource "aws_athena_named_query" "cloudfront_logs_saved_query" {
  for_each = { for idx, val in var.queries : idx => val }
  name     = each.value.name
  database = aws_athena_database.logs_database.name
  query    = each.value.query
}
