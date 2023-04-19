# This is where the global codebuild/codepipeline stuff is set up that the
# actual pipelines use.

resource "aws_iam_role" "auto_terraform" {
  name = "auto_terraform"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "auto_terraform" {
  role = aws_iam_role.auto_terraform.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
   {
      "Sid": "AssumeAutoTerraform",
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": [
          "arn:aws:iam::${var.sandbox_account_id}:role/AutoTerraform",
          "arn:aws:iam::${var.toolingprod_account_id}:role/AutoTerraform",
          "arn:aws:iam::${var.alpha_account_id}:role/AutoTerraform",
          "arn:aws:iam::${var.secopsdev_account_id}:role/AutoTerraform",
          "arn:aws:iam::${var.sms-sandbox_account_id}:role/AutoTerraform"
      ]
    },
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "ecr:CreateRepository",
        "ecr:DeleteLifecyclePolicy",
        "ecr:DeletePullThroughCacheRule",
        "ecr:DeleteRegistryPolicy",
        "ecr:DeleteRepositoryPolicy",
        "ecr:DescribePullThroughCacheRules",
        "ecr:DescribeRegistry",
        "ecr:DescribeRepositories",
        "ecr:GetLifecyclePolicy",
        "ecr:GetLifecyclePolicyPreview",
        "ecr:GetRegistryPolicy",
        "ecr:GetRegistryScanningConfiguration",
        "ecr:GetRepositoryPolicy",
        "ecr:ListTagsForResource",
        "ecr:PutImageScanningConfiguration",
        "ecr:PutImageTagMutability",
        "ecr:PutLifecyclePolicy",
        "ecr:PutRegistryPolicy",
        "ecr:PutRegistryScanningConfiguration",
        "ecr:PutReplicationConfiguration",
        "ecr:SetRepositoryPolicy",
        "ecr:TagResource",
        "ecr:UntagResource"
      ]
    },
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Resource": [
        "arn:aws:codestar-notifications:${var.region}:${data.aws_caller_identity.current.account_id}:notificationrule*"
      ],
      "Action": [
        "codestar-notifications:DescribeNotificationRule"
      ]
    },
    {
      "Effect": "Allow",
      "Resource": ["arn:aws:sns:${var.region}:${data.aws_caller_identity.current.account_id}:${var.events_sns_topic}"],
      "Action": [
        "sns:Publish"
      ]
    },
    {
      "Effect": "Allow",
      "Resource": [
        "arn:aws:codepipeline:${var.region}:${data.aws_caller_identity.current.account_id}:auto_terraform*"
      ],
      "Action": [
        "codepipeline:GetPipeline",
        "codepipeline:GetPipelineState"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs"
      ],
      "Resource": "*"
    },
    {
      "Effect":"Allow",
      "Action": [
        "s3:ListObjects",
        "s3:ListBucket",
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.codepipeline_bucket.arn}",
        "${aws_s3_bucket.codepipeline_bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterfacePermission"
      ],
      "Resource": [
        "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:network-interface/*"
      ],
      "Condition": {
        "StringEquals": {
          "ec2:Subnet": [
            "${aws_subnet.auto_terraform_private_a.arn}"
          ],
          "ec2:AuthorizedService": "codebuild.amazonaws.com"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "auto-tf-bucket-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_ownership_controls" "codepipeline_bucket" {
  bucket = aws_s3_bucket.codepipeline_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "codepipeline_bucket" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.codepipeline_bucket]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "codepipeline_bucket" {
  bucket = aws_s3_bucket.codepipeline_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name = "auto_tf_pipeline_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "auto_tf_codepipeline_policy"
  role = aws_iam_role.codepipeline_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.codepipeline_bucket.arn}",
        "${aws_s3_bucket.codepipeline_bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
