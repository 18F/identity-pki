data "aws_iam_policy_document" "redshift_kms" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    actions = [
      "kms:*",
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/PowerUser",
        aws_iam_role.redshift_role.arn
      ]
    }
    resources = [
      "*",
    ]
  }
}

data "aws_iam_policy_document" "redshift_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "redshift.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy" "insights" {
  arn = "arn:aws:iam::aws:policy/CloudWatchLambdaInsightsExecutionRolePolicy"
}

resource "aws_iam_role" "redshift_role" {
  name               = "${var.env_name}-redshift-iam-role"
  assume_role_policy = data.aws_iam_policy_document.redshift_policy_document.json
}

resource "aws_iam_policy" "redshift_s3_policy" {
  name        = "${var.env_name}-redshift-s3-policy"
  description = "S3 Policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:Get*",
          "s3:List*",
          "s3:Put*",
          "s3:*",
          "glue:*"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = "s3:PutObject",
        Resource = [
          "${aws_s3_bucket.analytics_logs.arn}",
          "${aws_s3_bucket.analytics_logs.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "redshift_policy_attachment" {
  name       = "${var.env_name}-redshift-policy-attachment"
  policy_arn = aws_iam_policy.redshift_s3_policy.arn
  roles = [
    aws_iam_role.redshift_role.name,
  ]
}
