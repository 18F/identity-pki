resource "aws_s3_bucket" "backups" {
  bucket = "login-gov-${var.env_name}-gitlabbackups-${data.aws_caller_identity.current.account_id}-${var.region}"
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
      days = 30
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

  # lifecycle {
  #   prevent_destroy = true
  # }
}

resource "aws_s3_bucket_public_access_block" "backups_access_block" {
  bucket                  = aws_s3_bucket.backups.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "config" {
  bucket = "login-gov-${var.env_name}-gitlabconfig-${data.aws_caller_identity.current.account_id}-${var.region}"
  acl    = "private"

  # force_destroy = true

  # lifecycle {
  #   prevent_destroy = true
  # }

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
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name        = "login-gov-${var.env_name}-gitlabcache-${data.aws_caller_identity.current.account_id}-${var.region}"
    Environment = "${var.env_name}"
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
  gitlab_buckets = [
    "login-gov-${var.env_name}-gitlabartifacts-${data.aws_caller_identity.current.account_id}-${var.region}",
    "login-gov-${var.env_name}-gitlabexternaldiffs-${data.aws_caller_identity.current.account_id}-${var.region}",
    "login-gov-${var.env_name}-gitlablfsobjects-${data.aws_caller_identity.current.account_id}-${var.region}",
    "login-gov-${var.env_name}-gitlabuploads-${data.aws_caller_identity.current.account_id}-${var.region}",
    "login-gov-${var.env_name}-gitlabpackages-${data.aws_caller_identity.current.account_id}-${var.region}",
    "login-gov-${var.env_name}-gitlabdependcyproxy-${data.aws_caller_identity.current.account_id}-${var.region}",
    "login-gov-${var.env_name}-gitlabtfstate-${data.aws_caller_identity.current.account_id}-${var.region}",
    "login-gov-${var.env_name}-gitlabpages-${data.aws_caller_identity.current.account_id}-${var.region}"
  ]
}

resource "aws_s3_bucket" "gitlab_buckets" {
  for_each = toset(local.gitlab_buckets)

  bucket = each.key
  acl    = "private"

  # force_destroy = true

  # lifecycle {
  #   prevent_destroy = true
  # }

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
