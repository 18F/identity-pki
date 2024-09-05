locals {
  archive_type = "db-export"
}

module "db_export_archive_bucket_primary" {
  source = "../../modules/logarchive_bucket"
  providers = {
    aws = aws.usw2
  }

  kms_key_id   = aws_kms_key.db_export_archive.arn
  archive_type = local.archive_type
}

module "db_export_archive_bucket_replica" {
  count  = var.enable_s3_replication ? 1 : 0
  source = "../../modules/logarchive_bucket"
  providers = {
    aws = aws.use1
  }

  kms_key_id   = aws_kms_replica_key.db_export_archive.arn
  archive_type = local.archive_type
}

data "aws_iam_policy_document" "db_s3_replication_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "db_s3_replication" {
  count              = var.enable_s3_replication ? 1 : 0
  name               = "db_s3_replication_db_export_archive"
  assume_role_policy = data.aws_iam_policy_document.db_s3_replication_assume_role.json
}

data "aws_iam_policy_document" "db_s3_replication" {
  count = var.enable_s3_replication ? 1 : 0
  statement {
    sid    = "AllowGettingBucketInformation"
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]
    resources = [module.db_export_archive_bucket_primary.bucket_arn]
  }

  statement {
    sid    = "AllowGettingObjectVersionInformation"
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]

    resources = ["${module.db_export_archive_bucket_primary.bucket_arn}/*"]
  }

  statement {
    sid    = "AllowReplicationToDestinationBucket"
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]
    resources = ["${module.db_export_archive_bucket_replica[count.index].bucket_arn}/*"]
  }

  statement {
    sid    = "AllowDecryptionWithSourceKey"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      aws_kms_key.db_export_archive.arn
    ]
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values = [
        "s3.${module.db_export_archive_bucket_primary.bucket_region}.amazonaws.com"
      ]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values = [
        "${module.db_export_archive_bucket_primary.bucket_arn}/*"
      ]
    }
  }

  statement {
    sid    = "AllowEncryptionWithReplicaKey"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey",
    ]
    resources = [
      aws_kms_replica_key.db_export_archive.arn
    ]
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values = [
        "s3.${module.db_export_archive_bucket_replica[count.index].bucket_region}.amazonaws.com"
      ]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values = [
        "${module.db_export_archive_bucket_replica[count.index].bucket_arn}/*"
      ]
    }
  }
}

resource "aws_iam_policy" "db_s3_replication" {
  count  = var.enable_s3_replication ? 1 : 0
  name   = "db_s3_replication"
  policy = data.aws_iam_policy_document.db_s3_replication[count.index].json
}

resource "aws_iam_role_policy_attachment" "db_s3_replication" {
  count      = var.enable_s3_replication ? 1 : 0
  role       = aws_iam_role.db_s3_replication[count.index].name
  policy_arn = aws_iam_policy.db_s3_replication[count.index].arn
}

resource "aws_s3_bucket_replication_configuration" "db_export_archive" {
  count  = var.enable_s3_replication ? 1 : 0
  role   = aws_iam_role.db_s3_replication[count.index].arn
  bucket = module.db_export_archive_bucket_primary[count.index].bucket_name

  rule {
    id     = "1"
    status = "Enabled"

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket        = module.db_export_archive_bucket_replica[count.index].bucket_arn
      storage_class = "STANDARD"
      encryption_configuration {
        replica_kms_key_id = aws_kms_replica_key.db_export_archive.arn
      }
    }
  }
}
