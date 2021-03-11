resource "aws_kms_key" "idp_sqs" {
  count                   = var.idp_sqs_notifications_enabled ? 1 : 0
  description             = "IDP SQS Key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.idp_sqs.json
}

resource "aws_kms_alias" "idp_sqs" {
  count         = var.idp_sqs_notifications_enabled ? 1 : 0
  name          = "alias/${var.env_name}-idp-sqs"
  target_key_id = aws_kms_key.idp_sqs[0].key_id
}

data "aws_iam_policy_document" "idp_sqs" {
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

  statement {
    sid    = "Allow access for Key Administrators"
    effect = "Allow"
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
    ]
    resources = [
      "*",
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/FullAdministrator"
      ]
    }
  }
  statement {
    sid    = "Allow access for Power Users"
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt",
    ]
    resources = [
      "*",
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/PowerUser"
      ]
    }
  }
}

resource "aws_sqs_queue" "risc_notifications_dead_letter" {
  count                             = var.idp_sqs_notifications_enabled ? 1 : 0
  name                              = "${var.env_name}-risc-notifications-dlq"
  message_retention_seconds         = 1209600
  visibility_timeout_seconds        = 30
  kms_master_key_id                 = aws_kms_key.idp_sqs[0].arn
  kms_data_key_reuse_period_seconds = 300
  tags = {
    environment = var.env_name
  }
}

resource "aws_sqs_queue" "risc_notifications" {
  count                      = var.idp_sqs_notifications_enabled ? 1 : 0
  name                       = "${var.env_name}-risc-notifications"
  message_retention_seconds  = 345600
  visibility_timeout_seconds = 30
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.risc_notifications_dead_letter[0].arn
    maxReceiveCount     = 3
  })
  kms_master_key_id                 = aws_kms_key.idp_sqs[0].arn
  kms_data_key_reuse_period_seconds = 300
  tags = {
    environment = var.env_name
  }
}

resource "aws_iam_role_policy" "idp_kms_sqs" {
  count  = var.idp_sqs_notifications_enabled ? 1 : 0
  name   = "${var.env_name}-idp-kms-sqs"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.idp_kms_sqs.json
}

data "aws_iam_policy_document" "idp_kms_sqs" {
  statement {
    sid    = "IDPKMSFORSQS"
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt",
    ]
    resources = [
      aws_kms_key.idp_sqs[0].arn,
    ]
  }
  statement {
    sid    = "IDPSQS"
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
    ]
    resources = [
      aws_sqs_queue.risc_notifications[0].arn
    ]
  }
}
