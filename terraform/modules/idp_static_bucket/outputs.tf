output "bucket_id" {
  value = aws_s3_bucket.idp_static_bucket.id
}

output "bucket_regional_domain_name" {
  value = aws_s3_bucket.idp_static_bucket.bucket_regional_domain_name
}