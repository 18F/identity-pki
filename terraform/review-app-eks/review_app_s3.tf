data "aws_s3_bucket" "inventory" {
  bucket = "login-gov.s3-inventory.${data.aws_caller_identity.current.account_id}-${var.region}"
}

data "aws_s3_bucket" "secrets" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
}

resource "aws_s3_bucket" "pivcac_cert_bucket" {
  bucket = "login-gov-pivcac-reviewapp.${data.aws_caller_identity.current.account_id}-${var.region}"

  tags = {
    Name = "login-gov-pivcac-reviewapp.${data.aws_caller_identity.current.account_id}-${var.region}"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pivcac_cert_bucket" {
  bucket = aws_s3_bucket.pivcac_cert_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket" "pivcac_public_cert_bucket" {
  bucket = "login-gov-pivcac-public-cert-reviewapp.${data.aws_caller_identity.current.account_id}-${var.region}"

  tags = {
    Name = "login-gov-pivcac-public-cert-reviewapp.${data.aws_caller_identity.current.account_id}-${var.region}"
  }
}

resource "aws_s3_bucket_versioning" "pivcac_public_cert_bucket" {
  bucket = aws_s3_bucket.pivcac_public_cert_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pivcac_public_cert_bucket" {
  bucket = aws_s3_bucket.pivcac_public_cert_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "pivcac_public_cert_bucket" {
  bucket = aws_s3_bucket.pivcac_public_cert_bucket.id

  rule {
    id     = "expiration"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 60
    }

    expiration {
      days = 60
    }
  }
}

module "pivcac_cert_bucket_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/s3_config"
  depends_on = [aws_s3_bucket.pivcac_cert_bucket]

  bucket_name_override = aws_s3_bucket.pivcac_cert_bucket.id
  region               = var.region
  inventory_bucket_arn = data.aws_s3_bucket.inventory.arn
}


module "pivcac_public_cert_bucket_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/s3_config"
  depends_on = [aws_s3_bucket.pivcac_public_cert_bucket]

  bucket_name_override = aws_s3_bucket.pivcac_public_cert_bucket.id
  region               = var.region
  inventory_bucket_arn = data.aws_s3_bucket.inventory.arn
}

resource "aws_s3_object" "review_app_dhparam_folder" {
  bucket = data.aws_s3_bucket.secrets.id
  key = "reviewapp/"
  source = "/dev/null"
}
