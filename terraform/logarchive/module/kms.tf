data "aws_iam_policy_document" "kms" {
  statement {
    sid    = "BasicKMSAccess"
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

resource "aws_kms_key" "logarchive" {
  description             = "KMS key for the ${local.aws_alias} S3 bucket (primary)"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  multi_region            = true

  policy = data.aws_iam_policy_document.kms.json
  tags = {
    Name = "${local.aws_alias}-s3"
  }
}

resource "aws_kms_alias" "logarchive" {
  name          = "alias/${local.aws_alias}-s3"
  target_key_id = aws_kms_key.logarchive.key_id
}

resource "aws_kms_replica_key" "logarchive" {
  provider = aws.use1

  description     = "KMS key for the ${local.aws_alias} S3 bucket (replica)"
  policy          = data.aws_iam_policy_document.kms.json
  primary_key_arn = aws_kms_key.logarchive.arn
}

resource "aws_kms_alias" "logarchive_replica" {
  provider = aws.use1

  name          = "alias/${local.aws_alias}-s3"
  target_key_id = aws_kms_replica_key.logarchive.key_id
}
