data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "shared" {
  statement {
    principals = {
      type = "AWS"
      identifiers = ["${var.power_users}"]
    }
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::login-gov-shared-data-${data.aws_caller_identity.current.account_id}"
    ]
  }

  statement {
    principals = {
      type = "AWS"
      identifiers = ["${var.power_users}"]
    }
    actions = [
      "s3:PutObject",
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::login-gov-shared-data-${data.aws_caller_identity.current.account_id}/*"
    ]
  }
}

resource "aws_s3_bucket" "shared" {
  bucket = "login-gov-shared-data-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
  policy = "${data.aws_iam_policy_document.shared.json}"
}

# Create a common bucket for storing ELB/ALB access logs
# The bucket name will be like this:
#   login-gov.elb-logs.<ACCOUNT_ID>-<AWS_REGION>
module "elb-logs" {
  source = "../terraform-modules/access_logs_bucket/"

  region = "${var.region}"
  bucket_name_prefix = "login-gov"
  use_prefix_for_permissions = false
}

output "elb_log_bucket" {
  value = "${module.elb-logs.bucket_name}"
}

# Bucket used for storing S3 access logs
resource "aws_s3_bucket" "s3-logs" {
  bucket = "login-gov.s3-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
  region = "${var.region}"
  acl = "log-delivery-write"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id = "expirelogs"
    enabled = true

    prefix  = "/"

    transition {
      days = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days = 365
      storage_class = "GLACIER"
    }

    expiration {
      # 5 years
      days = 1825
    }
  }
}

# policy allowing SES to upload files to the email bucket under /inbound/*
data "aws_iam_policy_document" "ses-upload" {
    statement {
        sid = "AllowSESPuts"
        effect = "Allow"
        principals = {
            type = "Service"
            identifiers = ["ses.amazonaws.com"]
        }
        actions = [
            "s3:PutObject"
        ]
        resources = [
            "arn:aws:s3:::login-gov.email.${data.aws_caller_identity.current.account_id}-${var.region}/inbound/*"
        ]
        condition {
            test = "StringEquals"
            variable = "aws:Referer"
            values = ["${data.aws_caller_identity.current.account_id}"]
        }
    }
}

# Bucket used for storing email stuff, such as inbound email
resource "aws_s3_bucket" "s3-email" {
  bucket = "login-gov.email.${data.aws_caller_identity.current.account_id}-${var.region}"
  region = "${var.region}"

  policy = "${data.aws_iam_policy_document.ses-upload.json}"

  lifecycle_rule {
    id = "expireinbound"
    enabled = true

    prefix  = "/inbound/"

    transition {
      days = 30
      storage_class = "STANDARD_IA"
    }

    # delete after 1 year
    expiration {
      days = 365
    }
  }
}

output "s3_log_bucket" {
  value = "${aws_s3_bucket.s3-logs.id}"
}
