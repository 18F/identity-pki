data "aws_iam_policy_document" "assume_role_lambda" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com",
      ]
    }
  }
}

data "aws_iam_policy_document" "allow_export_tasks" {

  statement {
    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }
    effect = "Allow"
    actions = [
      "s3:GetBucketAcl"
    ]
    resources = [
      aws_s3_bucket.analytics_export.arn
    ]
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"

      values = [for log_group in local.analytics_target_log_groups : "${log_group.resource.arn}:*"]
    }
  }
  statement {
    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.analytics_export.arn}/*"
    ]
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"

      values = [for log_group in local.analytics_target_log_groups : "${log_group.resource.arn}:*"]
    }
  }

  statement {
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:*",
    ]
    resources = [
      "${aws_s3_bucket.analytics_export.arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.env_name}_idp_iam_role"]
    }
    actions = [
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.analytics_export.arn,
      "${aws_s3_bucket.analytics_export.arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "replication" {

  statement {
    effect = "Allow"

    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]

    resources = [aws_s3_bucket.analytics_export.arn]
  }
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]

    resources = ["${aws_s3_bucket.analytics_export.arn}/*"]
  }
  statement {
    effect = "Allow"

    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:PutObject",
      "s3:ObjectOwnerOverrideToBucketOwner",
    ]

    resources = ["${local.analytics_import_arn}/*"]
  }
}

resource "aws_iam_policy" "replication" {

  name   = "login-gov-${var.env_name}-analytics-replication-policy"
  policy = data.aws_iam_policy_document.replication.json
}

resource "aws_iam_role_policy_attachment" "replication" {

  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}

data "aws_iam_policy_document" "s3_assume_role" {

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "replication" {

  name               = "login-gov-${var.env_name}-analytics-replication"
  assume_role_policy = data.aws_iam_policy_document.s3_assume_role.json
}


data "aws_iam_policy_document" "dms_s3" {


  statement {
    sid    = "AllowWriteToS3"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObjectTagging",
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetBucketAcl"
    ]
    resources = [
      aws_s3_bucket.analytics_export.arn,
      "${aws_s3_bucket.analytics_export.arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "dms_s3" {


  name   = "${var.env_name}-dms-s3"
  role   = var.dms_role.name
  policy = data.aws_iam_policy_document.dms_s3.json
}

resource "aws_dms_s3_endpoint" "analytics_export" {


  endpoint_id             = "${var.env_name}-analytics-export"
  endpoint_type           = "target"
  bucket_name             = aws_s3_bucket.analytics_export.id
  service_access_role_arn = var.dms_role.arn
  add_column_name         = true

  depends_on = [aws_iam_role_policy.dms_s3]
}

resource "aws_iam_role" "start_cw_export_task" {

  name               = "${local.start_cw_export_task_lambda_name}-execution"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json
}

resource "aws_iam_role_policy" "start_cw_export_task" {

  role   = aws_iam_role.start_cw_export_task.id
  policy = data.aws_iam_policy_document.start_cw_export_task.json

  depends_on = [aws_lambda_function.start_cw_export_task]
}

data "aws_iam_policy_document" "start_cw_export_task" {

  statement {
    sid    = "AllowCloudWatchLogsExportTasks"
    effect = "Allow"
    actions = [
      "logs:CreateExportTask",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
    ]

    resources = [for log_group in local.analytics_target_log_groups : "${log_group.resource.arn}:log-stream:"]
  }
  statement {
    sid    = "DescribeExportTasks"
    effect = "Allow"
    actions = [
      "logs:DescribeExportTasks",
    ]

    resources = ["arn:aws:logs:${var.region}:${var.account_id}:log-group::log-stream:"]
  }
  statement {
    sid    = "LogInvocationsToCloudwatch"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/lambda/${local.start_cw_export_task_lambda_name}:*"
    ]
  }
}

