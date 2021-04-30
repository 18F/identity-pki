resource "aws_kms_key" "awsmacietrail_dataevent" {
  description             = "Macie v2"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy = data.aws_iam_policy_document.awsmacietrail_dataevent.json
}

resource "aws_kms_alias" "awsmacietrail_dataevent" {
  name          = "alias/awsmacietrail-dataevent"
  target_key_id = aws_kms_key.awsmacietrail_dataevent.key_id
}

resource "aws_s3_bucket" "awsmacietrail_dataevent" {
  bucket = "${data.aws_caller_identity.current.account_id}-awsmacietrail-dataevent"
  acl = "private"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
	kms_master_key_id = aws_kms_key.kms_awsmacietrail_dataevent.arn
        sse_algorithm = "aws:kms"
      }
    }
  }
  policy = data.aws_iam_policy_document.s3_awsmacietrail_dataevent.json
}

// Recommended policies per the Macie console
data "aws_iam_policy_document" "kms_awsmacietrail_dataevent" {
  statement {
    sid    = "Allow Macie to use the key"
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = ["macie.amazonaws.com"]
    }
    actions = [
      "kms:GenerateDataKey",
      "kms:Encrypt",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid    = "Allow FullAdministrator to administer the key"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/FullAdministrator"
      ]
    }
    actions = [
      "kms:*",
    ]
    resources = [
      "*",
    ]
  }
}

data "aws_iam_policy_document" "s3_awsmacietrail_dataevent" {
  statement {
    sid = "Deny non-HTTPS access"
    effect = "Deny"
    principal = "*"
    action = "s3:*"
    resource = "arn:aws:s3:::917793222841-awsmacietrail-dataevent/*"
    condition {
      test = "Bool"
      variable = "aws:SecureTransport"
      value = "false"
    }
  }
  statement {
    sid = "Deny incorrect encryption header. This is optional"
    effect = "Deny"
    principal = {
      service = "macie.amazonaws.com"
    }
    action = "s3:PutObject"
    resource = "arn:aws:s3:::917793222841-awsmacietrail-dataevent/*"
    condition {
      test = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      value = "arn:aws:kms:us-west-2:917793222841:key/82338288-a8af-4a2c-96d5-98df8bed932e"
    }
  }
  statement {
    sid = "Deny unencrypted object uploads. This is optional"
    effect = "Deny"
    principal = {
      service = "macie.amazonaws.com"
    }
    action = "s3:PutObject"
    resource = "arn:aws:s3:::917793222841-awsmacietrail-dataevent/*"
    condition {
      test = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      value = "aws:kms"
    }
  }
  statement {
    sid = "Allow Macie to upload objects to the bucket"
    effect = "Allow"
    principal = {
      service = "macie.amazonaws.com"
    }
    action = "s3:PutObject"
    resource = "arn:aws:s3:::917793222841-awsmacietrail-dataevent/*"
  }
  statement {
    sid = "Allow Macie to use the getBucketLocation operation"
    effect = "Allow"
    principal = {
      service = "macie.amazonaws.com"
    }
    action = "s3:GetBucketLocation"
    resource = "arn:aws:s3:::917793222841-awsmacietrail-dataevent"
  }
  
  statement {
    sid    = "Allow FullAdministrator to administer the bucket"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/FullAdministrator"
      ]
    }
    actions = [
      "s3:*",
    ]
    resources = [
      "*",
    ]
  }
}
