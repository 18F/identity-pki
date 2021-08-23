data "aws_caller_identity" "current" {}

locals {
  # PostgreSQL parameter group family names changed from X.Y to just X after major version 9
  rds_engine_version_short = length(regexall("^9\\.", var.rds_engine_version)) > 0 ? join(".", [for v in [0, 1] : split(".", var.rds_engine_version)[v]]) : split(".", var.rds_engine_version)[0]
}

resource "aws_db_parameter_group" "force_ssl" {
  name_prefix = "${var.name}-${var.env_name}-idp${var.suffix}-${var.rds_engine}${replace(local.rds_engine_version_short, ".", "")}-"

  # Before changing this value, make sure the parameters are correct for the
  # version you are upgrading to.  See
  # http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.html.
  family = "${var.rds_engine}${local.rds_engine_version_short}"

  parameter {
    name         = "rds.force_ssl"
    value        = "1"
    apply_method = "pending-reboot"
  }

  # Setting to 30 minutes, RDS requires value in ms
  # https://aws.amazon.com/blogs/database/best-practices-for-amazon-rds-postgresql-replication/
  parameter {
    name  = "max_standby_archive_delay"
    value = "1800000"
  }

  # Setting to 30 minutes, RDS requires value in ms
  # https://aws.amazon.com/blogs/database/best-practices-for-amazon-rds-postgresql-replication/
  parameter {
    name  = "max_standby_streaming_delay"
    value = "1800000"
  }

  # Log all Data Definition Layer changes (ALTER, CREATE, etc.)
  parameter {
    name  = "log_statement"
    value = "ddl"
  }

  # Log all slow queries that take longer than specified time in ms
  parameter {
    name  = "log_min_duration_statement"
    value = "250" # 250 ms
  }

  # Log lock waits
  parameter {
    name  = "log_lock_waits"
    value = "1"
  }

  # Log lock waits
  parameter {
    name  = "log_lock_waits"
    value = "1"
  }

  # Log autovacuum task that take more than 1 sec
  parameter {
    name  = "rds.force_autovacuum_logging_level"
    value = "log"
  }
  parameter {
    name  = "log_autovacuum_min_duration"
    value = 1000
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

