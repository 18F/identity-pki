data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "secrets" {
  bucket = "${var.bucket_name_prefix}.${var.secrets_bucket_type}.${data.aws_caller_identity.current.account_id}-${var.region}"
  acl    = "private"
  force_destroy = "${var.force_destroy}"

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
}

resource "aws_s3_bucket_policy" "kms_encryption_policy" {
  count = "${var.use_kms == true ? 1 : 0}"
  bucket = "${aws_s3_bucket.secrets.id}"
  policy = <<EOF
{
  "Version":"2012-10-17",
  "Id":"PutObjPolicy-${aws_s3_bucket.secrets.id}",
  "Statement":[{
    "Sid":"DenyUnEncryptedObjectUploads",
    "Effect":"Deny",
    "Principal":"*",
    "Action":"s3:PutObject",
    "Resource":"arn:aws:s3:::${aws_s3_bucket.secrets.id}/*",
    "Condition":{
      "StringNotEquals":{
        "s3:x-amz-server-side-encryption":"aws:kms",
      }
    }
  }]
}
  EOF
}
