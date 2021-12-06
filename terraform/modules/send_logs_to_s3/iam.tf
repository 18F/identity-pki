data "aws_iam_policy_document" "kinesis_firehose_stream_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
}
data "aws_iam_policy_document" "kinesis_s3_kms" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    actions = [
      "kms:*",
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
    resources = [
      "*",
    ]
  }
}


data "aws_iam_policy_document" "kinesis_firehose_access_bucket_assume_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]

    resources = [
      aws_s3_bucket.kinesis_firehose_stream_bucket.arn,
      "${aws_s3_bucket.kinesis_firehose_stream_bucket.arn}/*",
    ]
  }
  statement {
    effect = "Allow"

    actions = [
      "logs:PutLogEvents"
    ]

    resources = [
      aws_cloudwatch_log_group.kinesis_firehose_stream_logging_group.arn
    ]
  }
  statement {

    effect = "Allow"
    actions = [
      "kms:Decrypt",
    "kms:GenerateDataKey"]

    resources = [
      aws_kms_key.kinesis_firehose_stream_bucket.arn
    ]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values = [
        "s3.${var.region}.amazonaws.com"
      ]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values = [aws_s3_bucket.kinesis_firehose_stream_bucket.arn,
      "${aws_s3_bucket.kinesis_firehose_stream_bucket.arn}/*"]
    }
  }
}

resource "aws_iam_role" "kinesis_firehose_stream_role" {
  name               = "${var.env_name}-kinesis_firehose_stream_role"
  assume_role_policy = data.aws_iam_policy_document.kinesis_firehose_stream_assume_role.json
}

resource "aws_iam_role_policy" "kinesis_firehose_access_bucket_policy" {
  name   = "kinesis_firehose_access_bucket_policy"
  role   = aws_iam_role.kinesis_firehose_stream_role.name
  policy = data.aws_iam_policy_document.kinesis_firehose_access_bucket_assume_policy.json
}


data "aws_iam_policy_document" "cloudwatch_logs_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cloudwatch_logs_assume_policy" {
  statement {
    effect    = "Allow"
    actions   = ["firehose:*"]
    resources = [aws_kinesis_firehose_delivery_stream.cloudwatch-exporter.arn]
  }
}

resource "aws_iam_role" "cloudwatch_logs_role" {
  name               = "${var.env_name}-cloudwatch_logs_role"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_logs_assume_role.json
}

resource "aws_iam_role_policy" "cloudwatch_logs_policy" {
  name   = "cloudwatch_logs_policy"
  role   = aws_iam_role.cloudwatch_logs_role.name
  policy = data.aws_iam_policy_document.cloudwatch_logs_assume_policy.json
}