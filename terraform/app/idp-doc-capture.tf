locals {
  doc_capture_s3_bucket_name_prefix = "login-gov-idp-doc-capture"
  doc_capture_lambda_name_prefix    = "${var.env_name}-idp-doc-capture-"
  doc_capture_ssm_parameter_prefix  = "/${var.env_name}/idp/lambda/upload/"
  doc_capture_key_alias_name        = "alias/${var.env_name}-idp-doc-capture"
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

resource "aws_s3_bucket_public_access_block" "idp_doc_capture" {
  bucket = aws_s3_bucket.idp_doc_capture.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#IDP Role access to S3 bucket and KMS key and Lambda functions
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

  statement {
    sid    = "ExecuteLambdaFunctions"
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:${local.doc_capture_lambda_name_prefix}*"
    ]
  }
}

module "idp_doc_capture_acuant_lambda" {
  source             = "../modules/idp_doc_capture_lambda"
  lambda_name        = "${local.doc_capture_lambda_name_prefix}acuant-upload"
  lambda_timeout     = 90
  lambda_memory      = 128
  lambda_package     = "../../lambda/idp-doc-capture/acuant/lambda_function.zip"
  lambda_description = "IDP Lambda function to upload doc files to Acuant"
  kms_key_arn        = aws_kms_key.idp_doc_capture.arn
  s3_bucket_arn      = aws_s3_bucket.idp_doc_capture.arn
  s3_bucket_name     = aws_s3_bucket.idp_doc_capture.id
  ssm_parameter_name = "${local.doc_capture_ssm_parameter_prefix}lambda/acuant"
}

module "idp_doc_capture_experian_lambda" {
  source             = "../modules/idp_doc_capture_lambda"
  lambda_name        = "${local.doc_capture_lambda_name_prefix}experian-upload"
  lambda_timeout     = 90
  lambda_memory      = 128
  lambda_package     = "../../lambda/idp-doc-capture/experian/lambda_function.zip"
  lambda_description = "IDP Lambda function to upload doc files to Experian"
  kms_key_arn        = aws_kms_key.idp_doc_capture.arn
  s3_bucket_arn      = aws_s3_bucket.idp_doc_capture.arn
  s3_bucket_name     = aws_s3_bucket.idp_doc_capture.id
  ssm_parameter_name = "${local.doc_capture_ssm_parameter_prefix}lambda/experian"
}

resource "aws_ssm_parameter" "kms_key_alias" {
  name  = "${local.doc_capture_ssm_parameter_prefix}kms/alias"
  type  = "String"
  value = local.doc_capture_key_alias_name
}