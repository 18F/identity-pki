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

