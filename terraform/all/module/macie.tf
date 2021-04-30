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
	kms_master_key_id = aws_kms_key.awsmacietrail_dataevent.arn
        sse_algorithm = "aws:kms"
      }
    }
  }
}


// Recommended policy per the Macie console
data "aws_iam_policy_document" "awsmacietrail_dataevent" {
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
