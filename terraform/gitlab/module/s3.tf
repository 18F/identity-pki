resource "aws_s3_bucket" "backups" {
  bucket = "gitlab-${var.env_name}-backups"
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    abort_incomplete_multipart_upload_days = 1
    id                                     = "expire-backups"
    enabled                                = true

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      days = 1
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name        = "gitlab-${var.env_name}-config"
    Environment = "${var.env_name}"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "backups_access_block" {
  bucket                  = aws_s3_bucket.backups.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "config" {
  bucket = "gitlab-${var.env_name}-config"
  acl    = "private"

  # force_destroy = true

  lifecycle {
    prevent_destroy = true
  }

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name        = "gitlab-${var.env_name}-config"
    Environment = "${var.env_name}"
  }
}

resource "aws_s3_bucket_public_access_block" "config_access_block" {
  bucket                  = aws_s3_bucket.config.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

locals {
  gitlab_buckets = [
    "gitlab-${var.env_name}-artifacts",
    "gitlab-${var.env_name}-external-diffs",
    "gitlab-${var.env_name}-lfs-objects",
    "gitlab-${var.env_name}-uploads",
    "gitlab-${var.env_name}-packages",
    "gitlab-${var.env_name}-dependency-proxy",
    "gitlab-${var.env_name}-terraform-state",
    "gitlab-${var.env_name}-pages"
  ]
}

resource "aws_s3_bucket" "gitlab_buckets" {
  for_each = toset(local.gitlab_buckets)

  bucket = each.key
  acl    = "private"

  # force_destroy = true

  lifecycle {
    prevent_destroy = true
  }

  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
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
