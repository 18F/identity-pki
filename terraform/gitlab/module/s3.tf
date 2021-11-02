
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
