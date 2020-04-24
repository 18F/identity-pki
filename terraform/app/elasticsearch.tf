resource "aws_iam_instance_profile" "elasticsearch" {
  name = "${var.env_name}_elasticsearch_instance_profile"
  role = aws_iam_role.elasticsearch.name
}

resource "aws_iam_role" "elasticsearch" {
  name               = "${var.env_name}_elasticsearch_iam_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_from_vpc.json
}

resource "aws_iam_role_policy" "elasticsearch-secrets-manager" {
  name   = "${var.env_name}-elasticsearch-secrets-manager"
  role   = aws_iam_role.elasticsearch.id
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

  tags = {
    Name = "login-gov-elasticsearch-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"
  }
  policy = data.aws_iam_policy_document.elasticsearch_bucket_policy.json

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
      "s3:*",
    ]
    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.elasticsearch.arn,
      ]
    }
    resources = [
      "arn:aws:s3:::login-gov-elasticsearch-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}",
      "arn:aws:s3:::login-gov-elasticsearch-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}/*",
    ]
  }
}

# These policies are all duplicated from base-permissions

resource "aws_iam_role_policy" "elasticsearch-secrets" {
  name   = "${var.env_name}-elasticsearch-secrets"
  role   = aws_iam_role.elasticsearch.id
  policy = data.aws_iam_policy_document.secrets_role_policy.json
}

# Role policy that associates it with the certificates_role_policy
resource "aws_iam_role_policy" "elasticsearch-certificates" {
  name   = "${var.env_name}-elasticsearch-certificates"
  role   = aws_iam_role.elasticsearch.id
  policy = data.aws_iam_policy_document.certificates_role_policy.json
}

# Role policy that associates it with the describe_instances_role_policy
resource "aws_iam_role_policy" "elasticsearch-describe_instances" {
  name   = "${var.env_name}-elasticsearch-describe_instances"
  role   = aws_iam_role.elasticsearch.id
  policy = data.aws_iam_policy_document.describe_instances_role_policy.json
}

resource "aws_iam_role_policy" "elasticsearch-cloudwatch-logs" {
  name   = "${var.env_name}-elasticsearch-cloudwatch-logs"
  role   = aws_iam_role.elasticsearch.id
  policy = data.aws_iam_policy_document.cloudwatch-logs.json
}

resource "aws_iam_role_policy" "elasticsearch-cloudwatch-agent" {
  name   = "${var.env_name}-elasticsearch-cloudwatch-agent"
  role   = aws_iam_role.elasticsearch.id
  policy = data.aws_iam_policy_document.cloudwatch-agent.json
}

resource "aws_iam_role_policy" "elasticsearch-ssm-access" {
  name   = "${var.env_name}-elasticsearch-ssm-access"
  role   = aws_iam_role.elasticsearch.id
  policy = data.aws_iam_policy_document.ssm_access_role_policy.json
}

# </end> base-permissions policies
