terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  pgroup_family = join("", [var.db_engine, split(".", var.db_engine_version)[0]])
  db_name = var.db_name_override == "" ? (
  "${var.env_name}-${var.db_identifier}") : var.db_name_override
  db_name_prefix = join("-", [
    var.name, var.env_name, var.db_identifier, local.pgroup_family, ""
  ])
}

## parameter groups below will be created IFF their corresponding var isn't empty ##

# RDS (used by gitlab DBs)

resource "aws_db_parameter_group" "force_ssl" {
  count       = length(var.pgroup_params) > 0 ? 1 : 0
  name_prefix = local.db_name_prefix

  # Before changing this value, make sure the parameters are correct for the
  # version you are upgrading to.  See
  # http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.html.
  family = local.pgroup_family

  # Setting to 30 minutes, RDS requires value in ms
  # https://aws.amazon.com/blogs/database/best-practices-for-amazon-rds-postgresql-replication/
  parameter {
    name  = "max_standby_archive_delay"
    value = "1800000"
  }

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

# Aurora (used by idp/worker/dashboard DBs)

resource "aws_rds_cluster_parameter_group" "aurora" {
  count       = length(var.cluster_pgroup_params) > 0 ? 1 : 0
  name        = "${local.db_name}-${local.pgroup_family}-cluster"
  family      = local.pgroup_family
  description = "${local.pgroup_family} parameter group for ${local.db_name} cluster"

  dynamic "parameter" {
    for_each = var.cluster_pgroup_params
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

resource "aws_db_parameter_group" "aurora" {
  count       = length(var.db_pgroup_params) > 0 ? 1 : 0
  name        = "${local.db_name}-${local.pgroup_family}-db"
  family      = local.pgroup_family
  description = "${local.pgroup_family} parameter group for ${local.db_name} instances"

  dynamic "parameter" {
    for_each = var.db_pgroup_params
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
  description             = "${replace(var.db_identifier, "idp", "IDP")} RDS DB Key"
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
  name          = "alias/${var.env_name}-${var.db_identifier}-rds"
  target_key_id = aws_kms_key.idp_rds.key_id
}

