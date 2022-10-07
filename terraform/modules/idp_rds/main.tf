terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  # PostgreSQL param group family names changed from X.Y to X after major version 9
  rds_engine_version_short = split(".", var.rds_engine_version)[0]
}

resource "aws_db_parameter_group" "force_ssl" {
  count       = length(var.pgroup_params) > 0 ? 1 : 0
  name_prefix = "${var.name}-${var.env_name}-idp${var.suffix}-${var.rds_engine}${replace(local.rds_engine_version_short, ".", "")}-"

  # Before changing this value, make sure the parameters are correct for the
  # version you are upgrading to.  See
  # http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.html.
  family = "${var.rds_engine}${local.rds_engine_version_short}"

  # Setting to 30 minutes, RDS requires value in ms
  # https://aws.amazon.com/blogs/database/best-practices-for-amazon-rds-postgresql-replication/
  parameter {
    name  = "max_standby_archive_delay"
    value = "1800000"
  }

  # additional parameters pulled from var.pgroup_params so that we can use those
  # params in Aurora in the future
  dynamic "parameter" {
    for_each = var.pgroup_params
    iterator = pblock

    content {
      name         = pblock.value.name
      value        = pblock.value.value
      apply_method = lookup(pblock.value, "method", "immediate")
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# kms key for db encryption.  currently usw2 uses the default aws/rds key.
# need cmk for cross region copying
resource "aws_kms_key" "idp_rds" {
  description             = "IDP${var.suffix} RDS DB Key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.idp_rds.json
}

data "aws_iam_policy_document" "idp_rds" {
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
    sid    = "Allow RDS Access"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = [
      "*",
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS",
      ]
    }
  }

  statement {
    sid    = "Allow attachment of resources"
    effect = "Allow"
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant",
    ]
    resources = [
      "*",
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS",
      ]
    }
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"

      values = [
        "true",
      ]
    }
  }
}

resource "aws_kms_alias" "idp_rds" {
  name          = "alias/${var.env_name}-idp${var.suffix}-rds"
  target_key_id = aws_kms_key.idp_rds.key_id
}

