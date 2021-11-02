resource "aws_s3_bucket" "guard_duty_threat_feed_s3_bucket" {
  bucket = "${var.guard_duty_threat_feed_name}-${var.account_id}-${var.aws_region}"
  acl    = "private"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  lifecycle {
    prevent_destroy = true
  }
}