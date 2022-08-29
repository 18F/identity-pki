data "aws_caller_identity" "current" {
}

locals {
  inventory_bucket_arn = "arn:aws:s3:::${var.bucket_name_prefix}.s3-inventory.${data.aws_caller_identity.current.account_id}-${var.region}"
}

resource "aws_s3_bucket" "transfer_utility" {
  bucket        = "${var.bucket_name_prefix}.${var.bucket_name}.${data.aws_caller_identity.current.account_id}-${var.region}"
  force_destroy = var.force_destroy

  tags = {
    Name        = var.bucket_name_prefix
    Environment = "All"
  }
}

resource "aws_s3_bucket_logging" "transfer_utility_logging" {
  bucket        = aws_s3_bucket.transfer_utility.id
  target_bucket = var.logs_bucket
  target_prefix = "${var.bucket_name_prefix}.${var.bucket_name}.${data.aws_caller_identity.current.account_id}-${var.region}/"
}

resource "aws_s3_bucket_lifecycle_configuration" "transfer_utility_lifecycle" {
  bucket = aws_s3_bucket.transfer_utility.id
  rule {
    id = "expire_all_files"
    expiration {
      days = 1
    }
    status = "Enabled"
  }
}

#Explicitly ignoring versioning warnings.
#We don't want any persistent data in the transfer_utility
#tfsec:ignore:aws-s3-enable-versioning
resource "aws_s3_bucket_versioning" "transfer_utility_versioning" {
  bucket = aws_s3_bucket.transfer_utility.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "transfer_utility_sse" {
  bucket = aws_s3_bucket.transfer_utility.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.sse_algorithm
    }
  }
}

resource "aws_s3_bucket_acl" "transfer_utility_acl" {
  bucket = aws_s3_bucket.transfer_utility.id
  acl    = "private"
}

resource "aws_s3_bucket_policy" "transfer_utility_policy" {
  bucket = aws_s3_bucket.transfer_utility.id
  policy = data.aws_iam_policy_document.transfer_utility_policy_document.json
}

data "aws_eips" "all" {
}

data "aws_iam_policy_document" "transfer_utility_policy_document" {
  statement {
    principals {
      type = "AWS"
      identifiers = [
        "*",
      ]
    }

    sid = "DenyUnauthorizedAccess"

    effect = "Deny"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:GetObjectAcl",
      "s3:GetObjectAttributes",
      "s3:GetObjectLegalHold",
      "s3:GetObjectRetention",
      "s3:GetObjectTagging",
      "s3:GetObjectTorrent",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionAttributes",
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectVersionTorrent",
      "s3:PutObjectLegalHold",
      "s3:PutObjectRetention",
      "s3:PutObjectTagging",
      "s3:PutObjectVersionTagging",
      "s3:ReplicateObject",
      "s3:RestoreObject",
    ]

    resources = [
      aws_s3_bucket.transfer_utility.arn,
      "${aws_s3_bucket.transfer_utility.arn}/*",
    ]

    condition {
      test     = "NotIpAddress"
      variable = "aws:SourceIP"
      values   = concat(data.aws_eips.all.public_ips, var.permitted_ip_addresses)
    }
    condition {
      test     = "NotIpAddress"
      variable = "aws:VpcSourceIP"
      values = [
        "100.64.0.0/10",
        "172.16.0.0/22",
      ]
    }
  }
}

module "transfer_utility_bucket_config" {
  source     = "github.com/18F/identity-terraform//s3_config?ref=a6261020a94b77b08eedf92a068832f21723f7a2"
  depends_on = [aws_s3_bucket.transfer_utility]

  bucket_name_prefix   = var.bucket_name_prefix
  bucket_name          = var.bucket_name
  region               = var.region
  inventory_bucket_arn = local.inventory_bucket_arn
}
