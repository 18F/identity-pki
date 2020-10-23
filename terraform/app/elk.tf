resource "aws_iam_role" "elk_iam_role" {
  name               = "${var.env_name}_elk_iam_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_from_vpc.json
}

resource "aws_iam_instance_profile" "elk_instance_profile" {
  name = "${var.env_name}_elk_instance_profile"
  role = aws_iam_role.elk_iam_role.name
}

data "aws_iam_policy_document" "logbucketpolicy" {
  # allow elk host to read from ELB log buckets
  statement {
    actions = [
      "s3:ListBucket",
      "s3:ListObjects",
    ]
    resources = [
      "arn:aws:s3:::login-gov-${var.env_name}-proxylogs",
      "arn:aws:s3:::login-gov-proxylogs-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}",
      "arn:aws:s3:::login-gov.elb-logs.${data.aws_caller_identity.current.account_id}-${var.region}",
      "arn:aws:s3:::login-gov.reports.${data.aws_caller_identity.current.account_id}-${var.region}",
      "arn:aws:s3:::login-gov-cloudtrail-${data.aws_caller_identity.current.account_id}",
    ]
  }
  statement {
    actions = [
      "s3:GetObject",
      "s3:ListObjects",
    ]
    resources = [
      "arn:aws:s3:::login-gov-${var.env_name}-proxylogs/*",
      "arn:aws:s3:::login-gov-proxylogs-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}/*",
      "arn:aws:s3:::login-gov.elb-logs.${data.aws_caller_identity.current.account_id}-${var.region}/${var.env_name}/*",
      "arn:aws:s3:::login-gov.reports.${data.aws_caller_identity.current.account_id}-${var.region}/*",
      "arn:aws:s3:::login-gov-cloudtrail-${data.aws_caller_identity.current.account_id}/*",
    ]
  }

  statement {
    actions = [
      "logs:Describe*",
      "logs:Get*",
      "logs:TestMetricFilter",
      "logs:FilterLogEvents",
    ]
    resources = ["*"]
  }
  statement {
    actions = [
      "rds:DescribeDBLogFiles",
      "rds:DownloadDBLogFilePortion",
    ]
    resources = [
      aws_db_instance.idp.arn,
    ]
  }
  statement {
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::login-gov-${var.env_name}-logs",
      "arn:aws:s3:::login-gov-logs-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}",
    ]
  }
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:PutObjectAcl",
    ]
    resources = [
      "arn:aws:s3:::login-gov-${var.env_name}-logs/*",
      "arn:aws:s3:::login-gov-logs-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}/*",
    ]
  }
  statement {
    actions = [
      "s3:List*",
      "s3:GetObject",
    ]
    resources = [
      "arn:aws:s3:::login-gov-${var.env_name}-analytics-logs/*",
      "arn:aws:s3:::login-gov-${var.env_name}-analytics-logs",
      "arn:aws:s3:::login-gov-analytics-logs-${var.env_name}.*/*",
      "arn:aws:s3:::login-gov-analytics-logs-${var.env_name}.*",
    ]
  }
}

resource "aws_iam_role_policy" "elk_iam_role_policy" {
  name   = "${var.env_name}_elk_iam_role_policy"
  role   = aws_iam_role.elk_iam_role.id
  policy = data.aws_iam_policy_document.logbucketpolicy.json
}

resource "aws_iam_role_policy" "elk_secrets" {
  name   = "${var.env_name}_elk_secrets"
  role   = aws_iam_role.elk_iam_role.id
  policy = data.aws_iam_policy_document.secrets_role_policy.json
}

resource "aws_iam_role_policy" "elk_certificates" {
  name   = "${var.env_name}_elk_certificates"
  role   = aws_iam_role.elk_iam_role.id
  policy = data.aws_iam_policy_document.certificates_role_policy.json
}

resource "aws_iam_role_policy" "elk_describe_instances" {
  name   = "${var.env_name}_elk_describe_instances"
  role   = aws_iam_role.elk_iam_role.id
  policy = data.aws_iam_policy_document.describe_instances_role_policy.json
}

resource "aws_iam_role_policy" "elk-cloudwatch-logs" {
  name   = "${var.env_name}-elk-cloudwatch-logs"
  role   = aws_iam_role.elk_iam_role.id
  policy = data.aws_iam_policy_document.cloudwatch-logs.json
}

resource "aws_iam_role_policy" "elk-cloudwatch-agent" {
  name   = "${var.env_name}-elk-cloudwatch-agent"
  role   = aws_iam_role.elk_iam_role.id
  policy = data.aws_iam_policy_document.cloudwatch-agent.json
}

resource "aws_iam_role_policy" "elk-ssm-access" {
  name   = "${var.env_name}-elk-ssm-access"
  role   = aws_iam_role.elk_iam_role.id
  policy = data.aws_iam_policy_document.ssm_access_role_policy.json
}

resource "aws_iam_role_policy" "elk-sns-publish-alerts" {
  name   = "${var.env_name}-elk-sns-publish-alerts"
  role   = aws_iam_role.elk_iam_role.id
  policy = data.aws_iam_policy_document.sns-publish-alerts-policy.json
}

resource "aws_s3_bucket" "logbucket" {
  # TODO use terraform locals to compute this once we upgrade to 0.10.*
  bucket = "login-gov-logs-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"
  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "logexpire"
    prefix  = ""
    enabled = true

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }
    transition {
      days          = 365
      storage_class = "GLACIER"
    }
    expiration {
      days = 2190 # 6 years
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

module "logbucket_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=36ecdc74c3436585568fab7abddb3336cec35d93"

  bucket_name_override = aws_s3_bucket.logbucket.id
  region               = var.region
  inventory_bucket_arn = local.inventory_bucket_arn
}
