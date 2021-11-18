
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

resource "aws_iam_role_policy" "gitlab-s3buckets" {
  name   = "${var.env_name}-gitlab-s3buckets"
  role   = aws_iam_role.gitlab.id
  policy = <<EOM
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": ["s3:ListBucket"],
        "Resource": [
          "arn:aws:s3:::gitlab-${var.env_name}-artifacts",
          "arn:aws:s3:::gitlab-${var.env_name}-backups",
          "arn:aws:s3:::gitlab-${var.env_name}-external-diffs",
          "arn:aws:s3:::gitlab-${var.env_name}-lfs-objects",
          "arn:aws:s3:::gitlab-${var.env_name}-uploads",
          "arn:aws:s3:::gitlab-${var.env_name}-packages",
          "arn:aws:s3:::gitlab-${var.env_name}-dependency-proxy",
          "arn:aws:s3:::gitlab-${var.env_name}-terraform-state",
          "arn:aws:s3:::gitlab-${var.env_name}-pages"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ],
        "Resource": [
          "arn:aws:s3:::gitlab-${var.env_name}-artifacts/*",
          "arn:aws:s3:::gitlab-${var.env_name}-backups/*",
          "arn:aws:s3:::gitlab-${var.env_name}-external-diffs/*",
          "arn:aws:s3:::gitlab-${var.env_name}-lfs-objects/*",
          "arn:aws:s3:::gitlab-${var.env_name}-uploads/*",
          "arn:aws:s3:::gitlab-${var.env_name}-packages/*",
          "arn:aws:s3:::gitlab-${var.env_name}-dependency-proxy/*",
          "arn:aws:s3:::gitlab-${var.env_name}-terraform-state/*",
          "arn:aws:s3:::gitlab-${var.env_name}-pages/*"
        ]
      }
    ]
}
EOM
}

locals {
  gitlab_buckets = [
    "gitlab-${var.env_name}-artifacts",
    "gitlab-${var.env_name}-backups",
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

resource "aws_s3control_bucket_lifecycle_configuration" "backups" {
  bucket = aws_s3_bucket.gitlab_buckets["gitlab-${var.env_name}-backups"].arn

  rule {
    expiration {
      days = 30
    }

    abort_incomplete_multipart_upload_days {
      days = 30
    }

    noncurrent_version_expiration {
      days = 1
    }

    id = "expire-backups"
  }
}
