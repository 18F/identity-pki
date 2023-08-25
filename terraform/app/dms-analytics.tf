data "aws_ip_ranges" "s3_cidr_blocks" {
  regions  = [var.region]
  services = ["s3"]
}

resource "aws_network_acl_rule" "db-ingress-s3-ephemeral" {
  for_each       = var.enable_dms_analytics ? toset(data.aws_ip_ranges.s3_cidr_blocks.cidr_blocks) : []
  network_acl_id = module.network_uw2.db_nacl_id
  egress         = false
  from_port      = 32768
  to_port        = 61000
  protocol       = "tcp"
  rule_number    = index(data.aws_ip_ranges.s3_cidr_blocks.cidr_blocks, each.value) + 20
  rule_action    = "allow"
  cidr_block     = each.value
}

resource "aws_network_acl_rule" "db-egress-s3-https" {
  for_each       = var.enable_dms_analytics ? toset(data.aws_ip_ranges.s3_cidr_blocks.cidr_blocks) : []
  network_acl_id = module.network_uw2.db_nacl_id
  egress         = true
  from_port      = 443
  to_port        = 443
  protocol       = "tcp"
  rule_number    = index(data.aws_ip_ranges.s3_cidr_blocks.cidr_blocks, each.value) + 20
  rule_action    = "allow"
  cidr_block     = each.value
}


resource "aws_s3_bucket" "analytics_export" {
  count = var.enable_dms_analytics ? 1 : 0
  bucket = join(".", [
    "login-gov-analytics-export-${var.env_name}",
    "${data.aws_caller_identity.current.account_id}-${var.region}"
  ])
}

resource "aws_s3_bucket_ownership_controls" "analytics_export" {
  count  = var.enable_dms_analytics ? 1 : 0
  bucket = aws_s3_bucket.analytics_export[count.index].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "analytics_export" {
  count  = var.enable_dms_analytics ? 1 : 0
  bucket = aws_s3_bucket.analytics_export[count.index].id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.analytics_export]
}

resource "aws_s3_bucket_public_access_block" "analytics_export" {
  count  = var.enable_dms_analytics ? 1 : 0
  bucket = aws_s3_bucket.analytics_export[count.index].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "analytics_export" {
  count  = var.enable_dms_analytics ? 1 : 0
  bucket = aws_s3_bucket.analytics_export[count.index].bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "dms_s3" {
  count = var.enable_dms_analytics ? 1 : 0

  statement {
    sid    = "AllowWriteToS3"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObjectTagging",
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetBucketAcl"
    ]
    resources = [
      "${aws_s3_bucket.analytics_export[count.index].arn}",
      "${aws_s3_bucket.analytics_export[count.index].arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "dms_s3" {
  count = var.enable_dms_analytics ? 1 : 0

  name   = "${var.env_name}-dms-s3"
  role   = module.dms[0].dms_role.name
  policy = data.aws_iam_policy_document.dms_s3[count.index].json
}

resource "aws_dms_s3_endpoint" "analytics_export" {
  count = var.enable_dms_analytics ? 1 : 0

  endpoint_id             = "${var.env_name}-analytics-export"
  endpoint_type           = "target"
  bucket_name             = aws_s3_bucket.analytics_export[count.index].id
  service_access_role_arn = module.dms[0].dms_role.arn

  depends_on = [aws_iam_role_policy.dms_s3]
}
