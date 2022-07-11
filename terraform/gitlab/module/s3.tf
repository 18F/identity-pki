resource "aws_s3_bucket" "backups" {
  bucket = "login-gov-${var.env_name}-gitlabbackups-${data.aws_caller_identity.current.account_id}-${var.region}"

  tags = {
    Name        = "gitlab-${var.env_name}-backups"
    Environment = "${var.env_name}"
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [replication_configuration]
  }
}

resource "aws_s3_bucket_acl" "backups" {
  bucket = aws_s3_bucket.backups.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    id     = "expire-backups"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }

    expiration {
      days = var.gitlab_backup_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.gitlab_backup_retention_days
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "backups_access_block" {
  bucket                  = aws_s3_bucket.backups.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  role   = aws_iam_role.s3_replication.arn
  bucket = aws_s3_bucket.backups.id

  rule {
    id     = "gitlab"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.backups_dr.arn
      storage_class = "STANDARD"
    }
  }
}

resource "aws_s3_bucket" "backups_dr" {
  bucket   = "login-gov-${var.env_name}-gitlabbackups-${data.aws_caller_identity.current.account_id}-${var.dr_region}"
  provider = aws.dr

  tags = {
    Name        = "gitlab-${var.env_name}-drbackups"
    Environment = "${var.env_name}"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_acl" "backups_dr" {
  bucket   = aws_s3_bucket.backups_dr.id
  provider = aws.dr
  acl      = "private"
}

resource "aws_s3_bucket_versioning" "backups_dr" {
  bucket   = aws_s3_bucket.backups_dr.id
  provider = aws.dr

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backups_dr" {
  bucket   = aws_s3_bucket.backups_dr.id
  provider = aws.dr

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backups_dr" {
  bucket   = aws_s3_bucket.backups_dr.id
  provider = aws.dr

  rule {
    id     = "expire-backups"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }

    expiration {
      days = var.gitlab_backup_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.gitlab_backup_retention_days
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "backups_dr" {
  bucket   = aws_s3_bucket.backups_dr.id
  provider = aws.dr

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "backups_dr_access_block" {
  provider                = aws.dr
  bucket                  = aws_s3_bucket.backups_dr.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "config" {
  bucket = "login-gov-${var.env_name}-gitlabconfig-${data.aws_caller_identity.current.account_id}-${var.region}"
  # force_destroy = true

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "gitlab-${var.env_name}-config"
    Environment = "${var.env_name}"
  }
}

resource "aws_s3_bucket_acl" "config" {
  bucket = aws_s3_bucket.config.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "config" {
  bucket = aws_s3_bucket.config.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config" {
  bucket = aws_s3_bucket.config.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "allow_gitlab_config_access_from_envs" {
  bucket = aws_s3_bucket.config.id
  policy = data.aws_iam_policy_document.allow_gitlab_config_access_from_envs.json
}

locals {
  rootaccounts = formatlist("arn:aws:iam::%s:root", var.accountids)
}

data "aws_iam_policy_document" "allow_gitlab_config_access_from_envs" {
  statement {
    sid = "allowEnvRunners"
    principals {
      type        = "AWS"
      identifiers = local.rootaccounts
    }
    actions = [
      "s3:GetObject",
    ]
    resources = [
      aws_s3_bucket.config.arn,
      "${aws_s3_bucket.config.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_public_access_block" "config_access_block" {
  bucket                  = aws_s3_bucket.config.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "cache" {
  bucket = "login-gov-${var.env_name}-gitlabcache-${data.aws_caller_identity.current.account_id}-${var.region}"

  tags = {
    Name        = "login-gov-${var.env_name}-gitlabcache-${data.aws_caller_identity.current.account_id}-${var.region}"
    Environment = "${var.env_name}"
  }
}

resource "aws_s3_bucket_acl" "cache" {
  bucket = aws_s3_bucket.cache.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cache" {
  bucket = aws_s3_bucket.cache.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cache_access_block" {
  bucket                  = aws_s3_bucket.cache.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

locals {
  gitlab_buckets = formatlist(
    "login-gov-${var.env_name}-gitlab%s-${data.aws_caller_identity.current.account_id}-${var.region}",
    [
      "artifacts",
      "externaldiffs",
      "lfsobjects",
      "uploads",
      "packages",
      "dependcyproxy",
      "tfstate",
      "pages"
    ]
  )
}

resource "aws_s3_bucket" "gitlab_buckets" {
  for_each = toset(local.gitlab_buckets)

  bucket = each.key

  # force_destroy = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_acl" "gitlab_buckets" {
  for_each = toset(local.gitlab_buckets)
  bucket   = each.key
  acl = "private"
}

resource "aws_s3_bucket_versioning" "gitlab_buckets" {
  for_each = toset(local.gitlab_buckets)
  bucket   = each.key

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "gitlab_buckets" {
  for_each = toset(local.gitlab_buckets)
  bucket   = each.key

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "gitlab_buckets_access_block" {
  for_each                = toset(local.gitlab_buckets)
  bucket                  = aws_s3_bucket.gitlab_buckets[each.key].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
