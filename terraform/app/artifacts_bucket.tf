# this policy can allow any node/host to access the s3 artifacts bucket
data "aws_iam_policy_document" "download_artifacts_role_policy" {
  statement {
    sid    = "AllowBucketAndObjectsDownload"
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*",
    ]

    resources = [
      "arn:aws:s3:::login-gov.app-artifacts.${data.aws_caller_identity.current.account_id}-*/${var.env_name}/",
      "arn:aws:s3:::login-gov.app-artifacts.${data.aws_caller_identity.current.account_id}-*/${var.env_name}/*",
      "arn:aws:s3:::login-gov.app-artifacts.${data.aws_caller_identity.current.account_id}-*/common/",
      "arn:aws:s3:::login-gov.app-artifacts.${data.aws_caller_identity.current.account_id}-*/common/*",
    ]
  }

  # allow ls to work
  statement {
    sid    = "AllowRootAndTopListing"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:prefix"
      values   = ["", "common/", "${var.env_name}/"]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:delimiter"
      values   = ["/"]
    }
    resources = [
      "arn:aws:s3:::login-gov.app-artifacts.${data.aws_caller_identity.current.account_id}-*",
    ]
  }

  # allow subdirectory ls
  statement {
    sid    = "AllowSubListing"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["common/", "${var.env_name}/*"]
    }
    resources = [
      "arn:aws:s3:::login-gov.app-artifacts.${data.aws_caller_identity.current.account_id}-*",
    ]
  }
}

data "aws_iam_policy_document" "upload_artifacts_role_policy" {
  statement {
    sid    = "AllowBucketAndObjectsUpload"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:CreateMultipartUpload"
    ]

    resources = [
      "arn:aws:s3:::login-gov.app-artifacts.${data.aws_caller_identity.current.account_id}-*/${var.env_name}/",
      "arn:aws:s3:::login-gov.app-artifacts.${data.aws_caller_identity.current.account_id}-*/${var.env_name}/*",
      "arn:aws:s3:::login-gov.app-artifacts.${data.aws_caller_identity.current.account_id}-*/common/",
      "arn:aws:s3:::login-gov.app-artifacts.${data.aws_caller_identity.current.account_id}-*/common/*",
    ]
  }
}
