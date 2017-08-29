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

# TODO: this was created by hand but should be imported into terraform state
# Bucket used for storing S3 access logs
# At the moment, this should have the S3 log delivery group added by hand
#resource "aws_s3_bucket" "s3-logs" {
#  bucket = "login-gov.s3-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
#  region = "${var.region}"
#  policy = "${data.aws_iam_policy_document.logs.json}"
#  acl = "log-delivery-write"
#}
