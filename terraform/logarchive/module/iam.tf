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
      "kinesis:ListStreamConsumers",
    ]
    resources = [
      aws_kinesis_stream.logarchive.arn
    ]
  }

  statement {
    sid    = "AllowAccessToKinesisStreamConsumers"
    effect = "Allow"
    actions = [
      "kinesis:DescribeStreamConsumer",
      "kinesis:SubscribeToShard",
    ]
    resources = [
      aws_kinesis_stream_consumer.logarchive.arn
    ]
  }

  statement {
    sid    = "AllowSendingToCloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      aws_cloudwatch_log_group.logarchive_kinesis_lambda.arn,
      "${aws_cloudwatch_log_group.logarchive_kinesis_lambda.arn}:*"
    ]
  }

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
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]
    resources = [
      aws_kms_key.logarchive.arn
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
