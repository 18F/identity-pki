resource "aws_s3_bucket" "lambda_functions" {
  bucket = "${local.bucket_name_prefix}.lambda-functions.${data.aws_caller_identity.current.account_id}-${var.region}"
}

resource "aws_s3_bucket_acl" "lambda_functions" {
  bucket = aws_s3_bucket.lambda_functions.id
  acl    = "private"
}

# Policy covering uploads to the lambda functions bucket
resource "aws_s3_bucket_policy" "lambda_functions" {
  bucket = aws_s3_bucket.lambda_functions.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowProdAccountBucketRead",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::555546682965:root"
      },
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketAcl",
        "s3:GetBucketLocation"
      ],
      "Resource": "arn:aws:s3:::${aws_s3_bucket.lambda_functions.id}"
    }
  ]
}
POLICY
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lambda_functions" {
  bucket = aws_s3_bucket.lambda_functions.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "lambda_functions" {
  bucket = aws_s3_bucket.lambda_functions.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "lambda_functions" {
  bucket = aws_s3_bucket.lambda_functions.id

  target_bucket = local.s3_logs_bucket
  target_prefix = "${aws_s3_bucket.lambda_functions.id}/"
}

resource "aws_s3_bucket_lifecycle_configuration" "lambda_functions" {
  bucket = aws_s3_bucket.lambda_functions.id

  rule {
    id     = "inactive"
    status = "Enabled"

    filter {
      prefix = "/"
    }

    transition {
      days          = 180
      storage_class = "STANDARD_IA"
    }
  }
}

module "s3_lambda_functions_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../../identity-terraform/s3_config"

  bucket_name_override = aws_s3_bucket.lambda_functions.id
  region               = var.region
  inventory_bucket_arn = local.inventory_bucket_uw2_arn
  block_public_access  = true
}
