module "logarchive_bucket_primary" {
  source = "../../modules/logarchive_bucket"
  providers = {
    aws = aws.usw2
  }

  kms_key_id = aws_kms_key.logarchive.arn
}

module "logarchive_bucket_replica" {
  source = "../../modules/logarchive_bucket"
  providers = {
    aws = aws.use1
  }

  kms_key_id = aws_kms_replica_key.logarchive.arn
}

data "aws_iam_policy_document" "s3_replication_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "s3_replication" {
  depends_on = [
    module.logarchive_bucket_primary,
    module.logarchive_bucket_replica
  ]
  name               = "s3_replication_logarchive"
  assume_role_policy = data.aws_iam_policy_document.s3_replication_assume_role.json
}

data "aws_iam_policy_document" "s3_replication" {
  statement {
    sid    = "AllowGettingBucketInformation"
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]
    resources = [module.logarchive_bucket_primary.bucket_arn]
  }

  statement {
    sid    = "AllowGettingObjectVersionInformation"
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]

    resources = ["${module.logarchive_bucket_primary.bucket_arn}/*"]
  }

  statement {
    sid    = "AllowReplicationToDestinationBucket"
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]
    resources = ["${module.logarchive_bucket_replica.bucket_arn}/*"]
  }

  statement {
    sid    = "AllowDecryptionWithSourceKey"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      aws_kms_key.logarchive.arn
    ]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values = [
        "s3.${module.logarchive_bucket_primary.bucket_region}.amazonaws.com"
      ]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values = [
        module.logarchive_bucket_primary.bucket_arn
      ]
    }
  }

  statement {
    sid    = "AllowEncryptionWithReplicaKey"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
    ]
    resources = [
      aws_kms_replica_key.logarchive.arn
    ]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values = [
        "s3.${module.logarchive_bucket_replica.bucket_region}.amazonaws.com"
      ]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values = [
        module.logarchive_bucket_replica.bucket_arn
      ]
    }
  }
}

resource "aws_iam_policy" "s3_replication" {
  depends_on = [
    module.logarchive_bucket_primary.bucket_arn,
    module.logarchive_bucket_replica.bucket_arn
  ]
  name   = "s3_replication"
  policy = data.aws_iam_policy_document.s3_replication.json
}

resource "aws_iam_role_policy_attachment" "s3_replication" {
  depends_on = [
    module.logarchive_bucket_primary.bucket_arn,
    module.logarchive_bucket_replica.bucket_arn
  ]
  role       = aws_iam_role.s3_replication.name
  policy_arn = aws_iam_policy.s3_replication.arn
}

resource "aws_s3_bucket_replication_configuration" "logarchive" {
  depends_on = [
    module.logarchive_bucket_primary.bucket_arn,
    module.logarchive_bucket_replica.bucket_arn
  ]

  role   = aws_iam_role.s3_replication.arn
  bucket = module.logarchive_bucket_primary.bucket_name

  rule {
    id     = "1"
    status = "Enabled"

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket        = module.logarchive_bucket_replica.bucket_arn
      storage_class = "STANDARD"
      encryption_configuration {
        replica_kms_key_id = aws_kms_replica_key.logarchive.arn
      }
    }
  }
}
