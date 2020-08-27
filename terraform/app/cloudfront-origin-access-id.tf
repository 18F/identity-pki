# Note - There is a 100 OAI limit per-account - A switch
# to one account wide OAI may make sense when we are continerized.
resource "aws_cloudfront_origin_access_identity" "cloudfront_oai" {
  comment = "${var.env_name} - CloudFront access to static asset S3 buckets"
}

output "cloudfront_oai_arn" {
  value = aws_cloudfront_origin_access_identity.cloudfront_oai.iam_arn
}

output "cloudfront_oai_path" {
  value = aws_cloudfront_origin_access_identity.cloudfront_oai.cloudfront_access_identity_path
}
