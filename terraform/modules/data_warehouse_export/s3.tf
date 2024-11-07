resource "aws_s3_bucket" "analytics_export" {

  bucket = join("-", [
    "login-gov-analytics-export-${var.env_name}",
    "${var.account_id}-${var.region}"
  ])
}

module "analytics_export_bucket_config" {

  source = "github.com/18F/identity-terraform//s3_config?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/s3_config"
  depends_on = [aws_s3_bucket.analytics_export]

  bucket_name_override = aws_s3_bucket.analytics_export.id
  region               = var.region
  inventory_bucket_arn = var.inventory_bucket_arn
}

resource "aws_s3_bucket_versioning" "analytics_export" {

  bucket = aws_s3_bucket.analytics_export.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "analytics_export" {

  bucket = aws_s3_bucket.analytics_export.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_notification" "trigger_transform" {
  bucket = aws_s3_bucket.analytics_export.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.transform_cw_export.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "logs/"
    filter_suffix       = ".gz"
  }
}

resource "aws_s3_bucket_policy" "analytics_export_allow_export_tasks" {

  bucket = aws_s3_bucket.analytics_export.id
  policy = data.aws_iam_policy_document.allow_export_tasks.json
}

resource "aws_s3_bucket_acl" "analytics_export" {

  bucket = aws_s3_bucket.analytics_export.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.analytics_export]
}

resource "aws_s3_bucket_public_access_block" "analytics_export" {

  bucket = aws_s3_bucket.analytics_export.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "analytics_export" {

  bucket = aws_s3_bucket.analytics_export.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_replication_configuration" "to_analytics" {

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.analytics_export.id

  depends_on = [
    aws_s3_bucket_versioning.analytics_export
  ]

  rule {
    id     = "ToAnalyticsAccount"
    status = "Enabled"
    filter {}

    destination {

      bucket  = local.analytics_import_arn
      account = var.analytics_account_id

      access_control_translation {
        owner = "Destination"
      }

      metrics {
        status = "Enabled"
      }
    }

    delete_marker_replication {
      status = "Enabled"
    }
  }
}

resource "aws_s3_bucket" "idp_dw_tasks" {
  bucket = join("-", [
    "login-gov-idp-dw-tasks-${var.env_name}",
    "${var.account_id}-${var.region}"
  ])
}

module "idp_dw_tasks_bucket_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/s3_config"
  depends_on = [aws_s3_bucket.idp_dw_tasks]

  bucket_name_override = aws_s3_bucket.idp_dw_tasks.id
  region               = var.region
  inventory_bucket_arn = var.inventory_bucket_arn
}

resource "aws_s3_bucket_versioning" "idp_dw_tasks" {
  bucket = aws_s3_bucket.idp_dw_tasks.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "idp_dw_tasks" {

  bucket = aws_s3_bucket.idp_dw_tasks.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = module.column_compare_task.lambda_arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.idp_dw_tasks.arn
}

resource "aws_s3_bucket_notification" "trigger_compare_task" {
  bucket = aws_s3_bucket.idp_dw_tasks.id

  lambda_function {
    lambda_function_arn = module.column_compare_task.lambda_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "daily-sensitive-column-job/"
    filter_suffix       = ".json"
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}
