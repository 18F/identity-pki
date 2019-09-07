resource "aws_iam_role" "elk_iam_role" {
  name = "${var.env_name}_elk_iam_role"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_from_vpc.json}"
}

resource "aws_iam_instance_profile" "elk_instance_profile" {
  name = "${var.env_name}_elk_instance_profile"
  role = "${aws_iam_role.elk_iam_role.name}"
}

data "aws_iam_policy_document" "logbucketpolicy" {
  # allow elk host to read from ELB log buckets
  statement {
    actions = [
      "s3:ListBucket",
      "s3:ListObjects"
    ]
    resources = [
      "arn:aws:s3:::login-gov-${var.env_name}-proxylogs",
      "arn:aws:s3:::login-gov-proxylogs-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}",
      "arn:aws:s3:::login-gov.elb-logs.${data.aws_caller_identity.current.account_id}-${var.region}",
      "arn:aws:s3:::login-gov.waf-logs-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}",
      "arn:aws:s3:::login-gov.reports.${data.aws_caller_identity.current.account_id}-${var.region}"
    ]
  }
  statement {
    actions = [
      "s3:GetObject",
      "s3:ListObjects"
    ]
    resources = [
      "arn:aws:s3:::login-gov-${var.env_name}-proxylogs/*",
      "arn:aws:s3:::login-gov-proxylogs-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}/*",
      "arn:aws:s3:::login-gov.elb-logs.${data.aws_caller_identity.current.account_id}-${var.region}/${var.env_name}/*",
      "arn:aws:s3:::login-gov.waf-logs-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}/*",
      "arn:aws:s3:::login-gov.reports.${data.aws_caller_identity.current.account_id}-${var.region}/*"
    ]
  }

  statement {
    actions = [
      "logs:Describe*",
      "logs:Get*",
      "logs:TestMetricFilter",
      "logs:FilterLogEvents"
    ]
    resources = [ "*" ]
  }
  statement {
    actions = [
      "rds:DescribeDBLogFiles",
      "rds:DownloadDBLogFilePortion"
    ]
    resources = [
#      "arn:aws:rds:::login-${var.env_name}-idp"
      "${aws_db_instance.idp.arn}"
    ]
  }
  statement {
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::login-gov-${var.env_name}-logs",
      "arn:aws:s3:::login-gov-logs-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"

    ]
  }
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "arn:aws:s3:::login-gov-${var.env_name}-logs/*",
      "arn:aws:s3:::login-gov-logs-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}/*"
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
      "arn:aws:s3:::login-gov-analytics-logs-${var.env_name}.*"
    ]
  }
}

resource "aws_iam_role_policy" "elk_iam_role_policy" {
  name = "${var.env_name}_elk_iam_role_policy"
  role = "${aws_iam_role.elk_iam_role.id}"
  policy = "${data.aws_iam_policy_document.logbucketpolicy.json}"
}

resource "aws_iam_role_policy" "elk_secrets" {
  name = "${var.env_name}_elk_secrets"
  role = "${aws_iam_role.elk_iam_role.id}"
  policy = "${data.aws_iam_policy_document.secrets_role_policy.json}"
}

resource "aws_iam_role_policy" "elk_certificates" {
  name = "${var.env_name}_elk_certificates"
  role = "${aws_iam_role.elk_iam_role.id}"
  policy = "${data.aws_iam_policy_document.certificates_role_policy.json}"
}

resource "aws_iam_role_policy" "elk_describe_instances" {
  name = "${var.env_name}_elk_describe_instances"
  role = "${aws_iam_role.elk_iam_role.id}"
  policy = "${data.aws_iam_policy_document.describe_instances_role_policy.json}"
}

resource "aws_iam_role_policy" "elk-cloudwatch-logs" {
  name = "${var.env_name}-elk-cloudwatch-logs"
  role = "${aws_iam_role.elk_iam_role.id}"
  policy = "${data.aws_iam_policy_document.cloudwatch-logs.json}"
}

resource "aws_s3_bucket" "logbucket" {
  # TODO use terraform locals to compute this once we upgrade to 0.10.*
  bucket = "${ var.legacy_log_bucket_name ? "login-gov-${var.env_name}-logs" : "login-gov-logs-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}" }"
  versioning {
    enabled = true
  }

  lifecycle_rule {
    id = "logexpire"
    prefix = ""
    enabled = true

    transition {
      days = 90
      storage_class = "STANDARD_IA"
    }
    transition {
      days = 365
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

resource "aws_s3_bucket_notification" "analytics_lambda_log_notify" {
  # NB: an S3 bucket can have only one bucket notification
  # https://github.com/terraform-providers/terraform-provider-aws/issues/1715

  count  = "${var.analytics_lambda_arn_for_s3_notify == "" ? 0 : 1}"
  bucket = "${aws_s3_bucket.logbucket.id}"

  lambda_function {
    # this comes from aws_lambda_function.analytics_lambda.arn in the
    # terraform-analytics directory
    lambda_function_arn = "${var.analytics_lambda_arn_for_s3_notify}"
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".txt"
  }
}

resource "aws_s3_bucket" "elasticsearch_snapshot_bucket" {
  bucket = "login-gov-elasticsearch-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"

  tags {
    Name = "login-gov-elasticsearch-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"
  }
  policy = "${data.aws_iam_policy_document.elasticsearch_bucket_policy.json}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

data "aws_iam_policy_document" "elasticsearch_bucket_policy" {
  # allow elasticsearch hosts to write to ES snapshot bucket
  statement {
    actions = [
      "s3:*"
    ]
    principals = {
      type ="AWS"
      identifiers = [
        "${aws_iam_role.idp.arn}", # asg-*-elasticsearch uses this
        "${aws_iam_role.elk_iam_role.arn}"
      ]
    }

    resources = [
      "arn:aws:s3:::login-gov-elasticsearch-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}",
      "arn:aws:s3:::login-gov-elasticsearch-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}/*"
    ]
  }
}
