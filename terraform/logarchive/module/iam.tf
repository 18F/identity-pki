### S3/KMS, used by both Data Stream and Firehose

data "aws_iam_policy_document" "s3_kms_access" {
  statement {
    sid    = "AllowS3Access"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
      "s3:PutObjectAcl",
    ]
    resources = compact([
      module.logarchive_bucket_primary.bucket_arn,
      "${module.logarchive_bucket_primary.bucket_arn}/*",
    ])
  }

  statement {
    sid    = "AllowKMS"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      aws_kms_key.logarchive.arn
    ]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values = [
        "s3.${module.logarchive_bucket_primary.bucket_region}.amazonaws.com"
      ]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values = [
        module.logarchive_bucket_primary.bucket_arn
      ]
    }
  }
}

resource "aws_iam_policy" "s3_kms_access" {
  name        = "s3_kms_access"
  description = "Provides S3 / KMS access to the logarchive bucket."
  policy      = data.aws_iam_policy_document.s3_kms_access.json
}

### DATA STREAM + LAMBDA

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    sid     = "AllowAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_kinesis_access" {
  statement {
    sid    = "AllowAccessToKinesis"
    effect = "Allow"
    actions = [
      "kinesis:DescribeStream",
      "kinesis:DescribeStreamSummary",
      "kinesis:GetRecords",
      "kinesis:GetShardIterator",
      "kinesis:ListShards",
      "kinesis:ListStreams",
    ]
    resources = [
      aws_kinesis_stream.logarchive.arn
    ]
  }

  statement {
    sid    = "AllowSendingToCloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:PutLogEvents"
    ]
    resources = [
      aws_cloudwatch_log_group.logarchive_kinesis_lambda.arn
    ]
  }
}

resource "aws_iam_role" "logarchive_kinesis_lambda" {
  name               = "logarchive_kinesis_lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy" "lambda_kinesis_access" {
  name   = "lambda_kinesis_access"
  role   = aws_iam_role.logarchive_kinesis_lambda.name
  policy = data.aws_iam_policy_document.lambda_kinesis_access.json
}

resource "aws_iam_role_policy_attachment" "lambda_s3_kms_access" {
  role       = aws_iam_role.logarchive_kinesis_lambda.name
  policy_arn = aws_iam_policy.s3_kms_access.arn
}

### FIREHOSE

data "aws_iam_policy_document" "firehose_assume_role" {
  statement {
    sid     = "AllowAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

data "aws_iam_policy_document" "firehose_log_access" {
  statement {
    sid    = "AllowSendingToCloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:PutLogEvents"
    ]
    resources = [
      aws_cloudwatch_log_group.logarchive_firehose.arn
    ]
  }
}

resource "aws_iam_role" "logarchive_firehose" {
  name               = "logarchive_firehose"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
}

resource "aws_iam_role_policy" "firehose_log_access" {
  name   = "firehose_log_access"
  role   = aws_iam_role.logarchive_firehose.name
  policy = data.aws_iam_policy_document.firehose_log_access.json
}

resource "aws_iam_role_policy_attachment" "firehose_s3_kms_access" {
  role       = aws_iam_role.logarchive_firehose.name
  policy_arn = aws_iam_policy.s3_kms_access.arn
}
