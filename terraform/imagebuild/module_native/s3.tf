resource "aws_s3_bucket" "codepipeline" {
  bucket = local.codepipeline_s3_bucket_name

  tags = {
    Name        = local.codepipeline_s3_bucket_name
    Environment = var.env_name
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [replication_configuration]
  }
}

resource "aws_s3_bucket_versioning" "codepipeline" {
  bucket = aws_s3_bucket.codepipeline.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "codepipeline" {
  bucket = aws_s3_bucket.codepipeline.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "codepipeline" {
  depends_on = [aws_s3_bucket_versioning.codepipeline]

  bucket = aws_s3_bucket.codepipeline.id

  rule {
    id = "expire"

    expiration {
      days = 60
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "codepipeline" {
  bucket = aws_s3_bucket.codepipeline.id

  target_bucket = data.aws_s3_bucket.access_logging.id
  target_prefix = "${aws_s3_bucket.codepipeline.bucket}/"
}
