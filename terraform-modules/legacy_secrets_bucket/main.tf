# TODO delete this whole file as I'm pretty sure it's unused.

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "logs" {
  bucket = "${var.bucket_name_prefix}-${var.region}-${data.aws_caller_identity.current.account_id}-logs"
  acl    = "log-delivery-write"
  force_destroy = "${var.force_destroy}"

  tags {
    Name        = "${var.bucket_name_prefix}-logs"
    Environment = "All"
  }

  # In theory we should only put one copy of every file, so I don't think this
  # will increase space, just give us history in case we accidentally
  # delete/modify something.
  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket" "secrets" {
  bucket = "${var.bucket_name_prefix}-${var.region}-${data.aws_caller_identity.current.account_id}"
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
    target_bucket = "${aws_s3_bucket.logs.id}"
    # This is effectively the bucket name, but I can't self reference
    target_prefix = "${var.bucket_name_prefix}-${var.region}-${data.aws_caller_identity.current.account_id}/"
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
