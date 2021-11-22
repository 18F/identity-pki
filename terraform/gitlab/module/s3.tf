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
}

resource "aws_s3_bucket" "config" {
  bucket = "gitlab-${var.env_name}-config"
  acl    = "private"

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
