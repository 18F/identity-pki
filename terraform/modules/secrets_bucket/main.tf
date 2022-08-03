data "aws_caller_identity" "current" {
}

locals {
  inventory_bucket_arn = "arn:aws:s3:::${var.bucket_name_prefix}.s3-inventory.${data.aws_caller_identity.current.account_id}-${var.region}"
}

resource "aws_s3_bucket" "secrets" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = {
    Name        = var.bucket_name_prefix
    Environment = "All"
  }
}

resource "aws_s3_bucket_acl" "secrets" {
  bucket = aws_s3_bucket.secrets.id
  acl    = "private"
}

resource "aws_s3_bucket_object" "bigfix_folder" {
  bucket = aws_s3_bucket.secrets.id
  #    acl    = "private"
  key    = "common/soc_agents/bigfix/"
  source = "/dev/null"
}

resource "aws_s3_bucket_object" "endgame_folder" {
  bucket = aws_s3_bucket.secrets.id
  #   acl    = "private"
  key    = "common/soc_agents/endgame/"
  source = "/dev/null"
}

resource "aws_s3_bucket_object" "fireeye_folder" {
  bucket = aws_s3_bucket.secrets.id
  #  acl    = "private"
  key    = "common/soc_agents/fireeye/"
  source = "/dev/null"
}

resource "aws_s3_bucket_versioning" "secrets" {
  bucket = aws_s3_bucket.secrets.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "secrets" {
  bucket = aws_s3_bucket.secrets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.sse_algorithm
    }
  }
}

resource "aws_s3_bucket_policy" "secrets" {
  count  = var.policy == "" ? 0 : 1
  bucket = aws_s3_bucket.secrets.id
  policy = var.policy
}

resource "aws_s3_bucket_logging" "secrets" {
  bucket = aws_s3_bucket.secrets.id

  target_bucket = var.logs_bucket
  target_prefix = "${var.bucket_name}/"
}

module "secrets_bucket_config" {
  source     = "github.com/18F/identity-terraform//s3_config?ref=5d344d205dd09eb85d5de1ff1081c4a598afe433"
  depends_on = [aws_s3_bucket.secrets]

  bucket_name_prefix   = var.bucket_name_prefix
  bucket_name          = var.secrets_bucket_type
  region               = var.region
  inventory_bucket_arn = local.inventory_bucket_arn
}
