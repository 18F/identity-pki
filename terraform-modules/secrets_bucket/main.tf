data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "secrets" {
  bucket = "${var.bucket_name_prefix}.${var.secrets_bucket_type}.${data.aws_caller_identity.current.account_id}-${var.region}"
  acl    = "private"
  force_destroy = "${var.force_destroy}"

  policy = ""

  tags {
    Name        = "${var.bucket_name_prefix}"
    Environment = "All"
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "${var.logs_bucket}"
    # This is effectively the bucket name, but I can't self reference
    target_prefix = "${var.bucket_name_prefix}.${var.secrets_bucket_type}.${data.aws_caller_identity.current.account_id}-${var.region}/"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
}
