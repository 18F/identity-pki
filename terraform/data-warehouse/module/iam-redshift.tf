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
  description        = "Allows AWS Redshift to access AWS S3 resources."
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
          "s3:AbortMultipartUpload",
          "s3:BypassGovernanceRetention",
          "s3:CreateAccessGrant",
          "s3:CreateAccessPoint*",
          "s3:CreateJob",
          "s3:CreateMultiRegionAccessPoint",
          "s3:CreateStorageLensGroup",
          "s3:DeleteAccessGrant",
          "s3:DeleteAccessGrantsLocation",
          "s3:DeleteAccessPoint*",
          "s3:DeleteJobTagging",
          "s3:DeleteMultiRegionAccessPoint",
          "s3:DeleteObject*",
          "s3:DeleteStorage*",
          "s3:Describe*",
          "s3:GetAccessGrant",
          "s3:GetAccessGrant",
          "s3:GetAccessGrantsLocation",
          "s3:GetAccessGrantsLocation",
          "s3:GetAccessPoint*",
          "s3:GetAccessPoint*",
          "s3:GetAccountPublicAccessBlock",
          "s3:GetAccountPublicAccessBlock",
          "s3:GetBucketTagging",
          "s3:GetBucketTagging",
          "s3:GetJobTagging",
          "s3:GetJobTagging",
          "s3:GetMulti*",
          "s3:GetMulti*",
          "s3:GetObject",
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:GetObjectAcl",
          "s3:GetObjectLegalHold",
          "s3:GetObjectLegalHold",
          "s3:GetObjectRetention",
          "s3:GetObjectRetention",
          "s3:GetObjectTagging",
          "s3:GetObjectTagging",
          "s3:GetObjectTorrent",
          "s3:GetObjectTorrent",
          "s3:GetObjectVersion*",
          "s3:GetObjectVersion*",
          "s3:GetStorage*",
          "s3:GetStorage*",
          "s3:InitiateReplication",
          "s3:ListAccessGrantsInstances",
          "s3:ListAccessGrantsInstances",
          "s3:ListAccessPoints*",
          "s3:ListAccessPoints*",
          "s3:ListAllMyBuckets",
          "s3:ListAllMyBuckets",
          "s3:ListBucket",
          "s3:ListBucket",
          "s3:ListBucketVersions",
          "s3:ListBucketVersions",
          "s3:ListCallerAccessGrants",
          "s3:ListCallerAccessGrants",
          "s3:ListJobs",
          "s3:ListJobs",
          "s3:ListMultiRegionAccessPoints",
          "s3:ListMultiRegionAccessPoints",
          "s3:ListMultipartUploadParts",
          "s3:ListMultipartUploadParts",
          "s3:ListStorage*",
          "s3:ListStorage*",
          "s3:ListTagsForResource",
          "s3:ListTagsForResource",
          "s3:ObjectOwnerOverrideToBucketOwner",
          "s3:PauseReplication",
          "s3:PutAccessPoint*",
          "s3:PutAccessPoint*",
          "s3:PutAccountPublicAccessBlock",
          "s3:PutAccountPublicAccessBlock",
          "s3:PutBucketTagging",
          "s3:PutBucketTagging",
          "s3:PutJobTagging",
          "s3:PutJobTagging",
          "s3:PutMultiRegionAccessPointPolicy",
          "s3:PutMultiRegionAccessPointPolicy",
          "s3:PutObject*",
          "s3:PutObject*",
          "s3:PutStorage*",
          "s3:PutStorage*",
          "s3:Replicate*",
          "s3:RestoreObject",
          "s3:SubmitMultiRegionAccessPointRoutes",
          "s3:TagResource",
          "s3:UntagResource",
          "s3:Update*"
        ],
        Resource = [
          aws_s3_bucket.analytics_import.arn,
          "${aws_s3_bucket.analytics_import.arn}/*",
        ]
      },
      {
        Effect = "Allow",
        Action = "s3:PutObject",
        Resource = [
          aws_s3_bucket.analytics_logs.arn,
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
