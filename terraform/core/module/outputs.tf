output "s3_ses_logs_bucket" {
  value = aws_s3_bucket.exported_logs.id
}

output "region" {
  value = var.region
}