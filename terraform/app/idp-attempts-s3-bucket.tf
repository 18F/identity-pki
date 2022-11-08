# CMK and policy document
resource "aws_kms_key" "attempts_api_kms" {
  description             = "${var.env_name} KMS key for attempts api s3 bucket"
  deletion_window_in_days = 10

  policy = data.aws_iam_policy_document.attempts_api_kms.json
  tags = {
    Name        = "${var.env_name}-attempts-api-s3"
    Environment = "${var.env_name}"
  }
}

resource "aws_kms_alias" "attempts_api_kms" {
  name          = "alias/${var.env_name}-attempts-api-s3"
  target_key_id = aws_kms_key.attempts_api_kms.key_id
}

data "aws_iam_policy_document" "attempts_api_kms" {
  statement {
    sid       = "EnableIAMUserPermissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
  statement {
    sid    = "EncryptDecrypt"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.idp.arn,
        aws_iam_role.worker.arn
      ]
    }
  }
}

# Attempts API S3 Bucket Setup
resource "aws_s3_bucket" "attempts_api" {
  bucket = "login-gov-attempts-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"
  tags = {
    Environment = var.env_name
  }
}

resource "aws_s3_bucket_logging" "attempts_api" {
  bucket = aws_s3_bucket.attempts_api.id

  target_bucket = "login-gov.s3-access-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
  target_prefix = "${aws_s3_bucket.attempts_api.id}/"
}

resource "aws_s3_bucket_lifecycle_configuration" "attempts_api" {
  bucket = aws_s3_bucket.attempts_api.id

  rule {
    id = "ExpireObjects"
    expiration {
      days = 3
    }
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "attempts_api" {
  bucket = aws_s3_bucket.attempts_api.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.attempts_api_kms.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "attempts_api" {
  bucket = aws_s3_bucket.attempts_api.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_acl" "attempts_api" {
  bucket = aws_s3_bucket.attempts_api.id
  acl    = "private"
}

# <env>_idp_iam_role and <env>_worker_iam_role policy to access Attempts API S3 Bucket
data "aws_iam_policy_document" "attempts_api" {
  statement {
    sid    = "AllowKMSUse"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = [
      aws_kms_key.attempts_api_kms.arn
    ]
  }
  statement {
    sid    = "AllowAttemptsBucketList"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.attempts_api.arn
    ]
  }
  statement {
    sid    = "AllowAttemptsBucketGetPut"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.attempts_api.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "attempts_api" {
  name   = "${var.env_name}-attempts-api-s3-policy"
  policy = data.aws_iam_policy_document.attempts_api.json
}

resource "aws_iam_role_policy_attachment" "attempts_api" {
  for_each = toset([
    aws_iam_role.idp.name,
    aws_iam_role.worker.name
  ])
  role       = each.key
  policy_arn = aws_iam_policy.attempts_api.arn
}
