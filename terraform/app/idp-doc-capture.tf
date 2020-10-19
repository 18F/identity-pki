locals {
  doc_capture_s3_bucket_name_prefix = "login-gov-idp-doc-capture"
  doc_capture_key_alias_name        = "alias/${var.env_name}-idp-doc-capture"
  doc_capture_ssm_parameter_prefix  = "/${var.env_name}/idp/doc-capture/"
  doc_capture_domain_name           = var.env_name == "prod" ? "secure.${var.root_domain}" : "idp.${var.env_name}.${var.root_domain}"
}

resource "aws_kms_key" "idp_doc_capture" {
  description             = "IDP Doc Capture"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "idp_doc_capture" {
  name          = local.doc_capture_key_alias_name
  target_key_id = aws_kms_key.idp_doc_capture.key_id
}

resource "aws_s3_bucket" "idp_doc_capture" {
  bucket        = "${local.doc_capture_s3_bucket_name_prefix}-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"
  force_destroy = true
  acl           = "private"

  logging {
    target_bucket = "login-gov.s3-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
    target_prefix = "/${var.env_name}/s3-access-logs/l${local.doc_capture_s3_bucket_name_prefix}/"
  }

  tags = {
    Name = "${local.doc_capture_s3_bucket_name_prefix}-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.idp_doc_capture.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "delete"
    prefix  = "/"
    enabled = true

    expiration {
      days = 1
    }
    noncurrent_version_expiration {
      days = 1
    }
  }

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["POST", "PUT"]
    allowed_origins = ["https://${local.doc_capture_domain_name}"]
    expose_headers  = ["x-amz-request-id", "x-amz-id-2"]
  }
}

module "idp_doc_capture_bucket_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=36ecdc74c3436585568fab7abddb3336cec35d93"

  bucket_name_override = aws_s3_bucket.idp_doc_capture.id
  region               = var.region
  inventory_bucket_arn = local.inventory_bucket_arn
}

#IDP Role access to S3 bucket and KMS key
resource "aws_iam_role_policy" "idp_doc_capture" {
  name   = "${var.env_name}-idp-doc-capture"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.idp_doc_capture.json
}

data "aws_iam_policy_document" "idp_doc_capture" {
  statement {
    sid    = "KMSDocCaptureKeyAccess"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*"
    ]
    resources = [
      aws_kms_key.idp_doc_capture.arn,
    ]
  }

  statement {
    sid    = "S3DocCaptureUploadAccess"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]
    resources = [
      "${aws_s3_bucket.idp_doc_capture.arn}",
      "${aws_s3_bucket.idp_doc_capture.arn}/*"
    ]
  }
}

resource "aws_ssm_parameter" "kms_key_alias" {
  name  = "${local.doc_capture_ssm_parameter_prefix}kms/alias"
  type  = "String"
  value = local.doc_capture_key_alias_name
}

resource "aws_ssm_parameter" "kms_key_arn" {
  name = "${local.doc_capture_ssm_parameter_prefix}kms/arn"
  type  = "String"
  value = aws_kms_key.idp_doc_capture.arn
}

# starter value only
# real key will be populated by hand
resource "aws_ssm_parameter" "idp_key" {
  name = "${local.doc_capture_ssm_parameter_prefix}idp/key"
  description = "IDP callback key"
  type  = "SecureString"
  overwrite = false
  value = "Starter value"
}
