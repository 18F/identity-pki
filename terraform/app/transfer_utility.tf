locals {
  transfer_bucket = join(".", [
    "arn:aws:s3:::login-gov.transfer-utility",
    "${data.aws_caller_identity.current.account_id}-${var.region}"
    ]
  )
}

data "aws_iam_policy_document" "transfer_utility_policy" {
  statement {
    sid    = "AllowObjectsDownload"
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${local.transfer_bucket}/${var.env_name}/in/*"
    ]
  }
  statement {
    sid    = "AllowObjectsUpload"
    effect = "Allow"
    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${local.transfer_bucket}/${var.env_name}/out/*"
    ]
  }
  statement {
    sid    = "AllowBucketListing"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "${local.transfer_bucket}",
    ]
  }
  statement {
    sid    = "AllowListing"
    effect = "Allow"
    actions = [
      "s3:ListObjectsV2",
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:prefix"
      values   = ["${var.env_name}/"]
    }
    resources = [
      "${local.transfer_bucket}/${var.env_name}/in/*",
    ]
  }
}
