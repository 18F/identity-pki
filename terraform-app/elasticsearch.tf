resource "aws_iam_instance_profile" "elasticsearch" {
  name = "${var.env_name}_elasticsearch_instance_profile"
  role = "${aws_iam_role.elasticsearch.name}"
}

resource "aws_iam_role" "elasticsearch" {
  name = "${var.env_name}_elasticsearch_iam_role"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_from_vpc.json}"
}

resource "aws_iam_role_policy" "elasticsearch-secrets" {
  name = "${var.env_name}-elasticsearch-secrets"
  role = "${aws_iam_role.elasticsearch.id}"
  policy = "${data.aws_iam_policy_document.elasticsearch-secrets-role-policy.json}"
}

data "aws_iam_policy_document" "elasticsearch-secrets-role-policy" {
  statement {
    sid = "AllowBucketAndObjects"
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*"
    ]

    resources = [
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/common/",
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/common/*",
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/${var.env_name}/",
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/${var.env_name}/*",
    ]
  }

  # allow ls to work
  statement {
    sid = "AllowRootAndTopListing"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    condition {
      test = "StringEquals"
      variable = "s3:prefix"
      values = ["", "common/", "${var.env_name}/"]
    }
    condition {
      test = "StringEquals"
      variable = "s3:delimiter"
      values = ["/"]
    }
    resources = [
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*",
    ]
  }

  # allow subdirectory ls
  statement {
    sid = "AllowSubListing"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    condition {
      test = "StringLike"
      variable = "s3:prefix"
      values = ["common/", "${var.env_name}/*"]
    }
    resources = [
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*",
    ]
  }
}

resource "aws_iam_role_policy" "elasticsearch-secrets-manager" {
  name = "${var.env_name}-elasticsearch-secrets-manager"
  role = "${aws_iam_role.elasticsearch.id}"
  policy = <<EOM
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:DescribeSecret",
                "secretsmanager:List*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "secretsmanager:Get*",
            "Resource": [
                "arn:aws:secretsmanager:*:*:secret:global/common/*",
                "arn:aws:secretsmanager:*:*:secret:global/elasticsearch/*",
                "arn:aws:secretsmanager:*:*:secret:${var.env_name}/common/*",
                "arn:aws:secretsmanager:*:*:secret:${var.env_name}/elasticsearch/*"
            ]
        }
    ]
}
EOM
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
