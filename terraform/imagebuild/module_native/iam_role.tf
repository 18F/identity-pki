resource "aws_iam_role" "codepipeline" {
  name               = local.codepipeline_role_name
  description        = "Allows AWS CodePipeline in the imagebuild pipeline to start a build via AWS CodeBuild and access AWS S3 resources."
  assume_role_policy = data.aws_iam_policy_document.codepipeline.json
}

data "aws_iam_policy_document" "codepipeline_role" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning"
    ]
    resources = [
      "${aws_s3_bucket.codepipeline.arn}",
      "${aws_s3_bucket.codepipeline.arn}/*",
      "arn:aws:s3:::${var.git2s3_bucket_name}",
      "arn:aws:s3:::${var.git2s3_bucket_name}/*",
      "arn:aws:s3:::login-gov-public-artifacts-${data.aws_region.current.name}/packer_config/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.codepipeline.arn}",
      "${aws_s3_bucket.codepipeline.arn}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]
    resources = [
      "${aws_codebuild_project.base_image.arn}",
      "${aws_codebuild_project.rails_image.arn}"
    ]
  }
}

resource "aws_iam_role_policy" "codepipeline_role" {
  name   = "CodePipelineRolePolicy"
  role   = aws_iam_role.codepipeline.name
  policy = data.aws_iam_policy_document.codepipeline_role.json
}

resource "aws_iam_role" "codebuild" {
  name               = local.codebuild_role_name
  description        = "Allows AWS CodeBuild in the imagebuild pipeline to perform specific actions and access resources such as AWS S3 or CloudWatch."
  assume_role_policy = data.aws_iam_policy_document.codebuild.json
}

data "aws_iam_policy_document" "codebuild_base" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "${aws_cloudwatch_log_group.imagebuild_base.arn}:*",
      "${aws_cloudwatch_log_group.imagebuild_rails.arn}:*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation"
    ]
    resources = [
      aws_s3_bucket.codepipeline.arn,
      "${aws_s3_bucket.codepipeline.arn}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "codebuild:CreateReportGroup",
      "codebuild:CreateReport",
      "codebuild:UpdateReport",
      "codebuild:BatchPutTestCases"
    ]
    resources = [
      "arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:report-group/${local.base_pipeline_name}",
      "arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:report-group/${local.rails_pipeline_name}"
    ]
  }
}

data "aws_iam_policy_document" "codebuild_crissupb" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation"
    ]
    resources = [
      "${aws_s3_bucket.codepipeline.arn}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation"
    ]
    resources = [
      "arn:aws:s3:::codebuild-imagebaserole-outputbucket-k3ulvdsui2sy",
      "arn:aws:s3:::codebuild-imagebaserole-outputbucket-k3ulvdsui2sy/*"
    ]
  }
}


data "aws_iam_policy_document" "codebuild_s3_ro" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
    resources = [
      "arn:aws:s3:::${var.git2s3_bucket_name}/${local.identity_base_image_zip_s3_path}"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation"
    ]
    resources = [
      "arn:aws:s3:::${var.git2s3_bucket_name}"
    ]
  }
}

data "aws_iam_policy_document" "codebuild_vpc" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterfacePermission"
    ]
    resources = [
      "*",
    ]
    condition {
      test     = "StringEquals"
      variable = "ec2:Subnet"
      values = [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:subnet/${var.private_subnet_id}"
      ]
    }
  }
}

data "aws_iam_policy_document" "codebuild_cloudwatchevents" {
  statement {
    effect = "Allow"
    actions = [
      "events:PutEvents"
    ]
    resources = [
      "*",
    ]
  }
}

data "aws_iam_policy_document" "codebuild_iam" {
  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole",
      "iam:GetRole"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.packer_role_name}",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "iam:GetInstanceProfile"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/${local.packer_instance_profile_name}",
    ]
  }
}

data "aws_iam_policy_document" "codebuild_log" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = [
      "${aws_cloudwatch_log_group.imagebuild_base.arn}:*",
      "${aws_cloudwatch_log_group.imagebuild_rails.arn}:*"
    ]
  }
}

data "aws_iam_policy_document" "codebuild_packer" {
  statement {
    sid    = "Ec2KeypairAccess"
    effect = "Allow"
    actions = [
      "ec2:CreateKeypair",
      "ec2:DeleteKeypair"
    ]
    resources = [
      "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key-pair/*",
    ]
    condition {
      test     = "StringLike"
      variable = "ec2:KeyPairName"
      values = [
        "packer*"
      ]
    }
  }
  statement {
    sid    = "Ec2ModifyConditionals"
    effect = "Allow"
    actions = [
      "ec2:AttachVolume",
      "ec2:DeleteVolume",
      "ec2:DetachVolume",
      "ec2:ModifyInstanceAttribute",
      "ec2:StopInstances",
      "ec2:TerminateInstances"
    ]
    resources = [
      "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
    ]
    condition {
      test     = "StringEquals"
      variable = "ec2:InstanceProfile"
      values = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/${local.packer_instance_profile_name}"
      ]
    }
  }
  statement {
    sid    = "Ec2GeneralAllow"
    effect = "Allow"
    actions = [
      "ec2:CopyImage",
      "ec2:CreateImage",
      "ec2:CreateSnapshot",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:DeleteSnapshot",
      "ec2:DeregisterImage",
      "ec2:DescribeImageAttribute",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSnapshots",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:ModifyImageAttribute",
      "ec2:ModifySnapshotAttribute",
      "ec2:RegisterImage",
      "ec2:RunInstances",
      "ec2:StartInstances"
    ]
    resources = [
      "*",
    ]
  }
}

data "aws_iam_policy_document" "codebuild_parameter" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters"
    ]
    resources = [
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/CodeBuild/*"
    ]
  }
}

data "aws_iam_policy_document" "codebuild_pipeline" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
    resources = [
      "arn:aws:s3:::*-artifact*"
    ]
  }
}

data "aws_iam_policy_document" "codebuild_secrets_common" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
    resources = [
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}/common/GeoIP2-City.mmdb",
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}/common/pwned-passwords.txt"
    ]
  }
}

data "aws_iam_policy_document" "codebuild_source" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
    resources = [
      "arn:aws:s3:::${var.git2s3_bucket_name}/*"
    ]
  }
}


resource "aws_iam_role_policy" "codebuild_base" {
  name   = "CodeBuildBasePolicy"
  role   = aws_iam_role.codebuild.name
  policy = data.aws_iam_policy_document.codebuild_base.json
}

resource "aws_iam_role_policy" "codebuild_crissupb" {
  name   = "CodeBuildCrissupbPolicy"
  role   = aws_iam_role.codebuild.name
  policy = data.aws_iam_policy_document.codebuild_crissupb.json
}

resource "aws_iam_role_policy" "codebuild_s3_ro" {
  name   = "CodeBuildS3ROPolicy"
  role   = aws_iam_role.codebuild.name
  policy = data.aws_iam_policy_document.codebuild_s3_ro.json
}

resource "aws_iam_role_policy" "codebuild_vpc" {
  name   = "CodeBuildVPCPolicy"
  role   = aws_iam_role.codebuild.name
  policy = data.aws_iam_policy_document.codebuild_vpc.json
}

resource "aws_iam_role_policy" "codebuild_cloudwatchevents" {
  name   = "CodeBuildCloudWatchEventsPolicy"
  role   = aws_iam_role.codebuild.name
  policy = data.aws_iam_policy_document.codebuild_cloudwatchevents.json
}

resource "aws_iam_role_policy" "codebuild_iam" {
  name   = "CodeBuildIAMPolicy"
  role   = aws_iam_role.codebuild.name
  policy = data.aws_iam_policy_document.codebuild_iam.json
}

resource "aws_iam_role_policy" "codebuild_log" {
  name   = "CodeBuildLogPolicy"
  role   = aws_iam_role.codebuild.name
  policy = data.aws_iam_policy_document.codebuild_log.json
}

resource "aws_iam_role_policy" "codebuild_packer" {
  name   = "CodeBuildPackerPolicy"
  role   = aws_iam_role.codebuild.name
  policy = data.aws_iam_policy_document.codebuild_packer.json
}

resource "aws_iam_role_policy" "codebuild_parameter" {
  name   = "CodeBuildParameterPolicy"
  role   = aws_iam_role.codebuild.name
  policy = data.aws_iam_policy_document.codebuild_parameter.json
}

resource "aws_iam_role_policy" "codebuild_pipeline" {
  name   = "CodeBuildPipelinePolicy"
  role   = aws_iam_role.codebuild.name
  policy = data.aws_iam_policy_document.codebuild_pipeline.json
}

resource "aws_iam_role_policy" "codebuild_secrets_common" {
  name   = "CodeBuildSecretsCommonPolicy"
  role   = aws_iam_role.codebuild.name
  policy = data.aws_iam_policy_document.codebuild_secrets_common.json
}

resource "aws_iam_role_policy" "codebuild_source" {
  name   = "CodeBuildSourcePolicy"
  role   = aws_iam_role.codebuild.name
  policy = data.aws_iam_policy_document.codebuild_source.json
}

resource "aws_iam_role" "packer" {
  name               = local.packer_role_name
  description        = "Allows AWS CodeBuild in the imagebuild pipeline to generate AMIs using HashiCorp Packer."
  assume_role_policy = data.aws_iam_policy_document.packer.json
}

data "aws_iam_policy_document" "codebuild_packer_s3" {
  statement {
    sid    = "AllowBucketAndObjects"
    effect = "Allow"
    actions = [
      "s3:GetAccelerateConfiguration",
      "s3:GetAccess*",
      "s3:GetAccountPublicAccessBlock",
      "s3:GetAnalyticsConfiguration",
      "s3:GetBucket*",
      "s3:GetDataAccess",
      "s3:GetEncryptionConfiguration",
      "s3:GetIntelligentTieringConfiguration",
      "s3:GetInventoryConfiguration",
      "s3:GetJobTagging",
      "s3:GetLifecycleConfiguration",
      "s3:GetMetricsConfiguration",
      "s3:GetMulti*",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:GetObjectLegalHold",
      "s3:GetObjectRetention",
      "s3:GetObjectTagging",
      "s3:GetObjectTorrent",
      "s3:GetObjectVersion*",
      "s3:GetReplicationConfiguration",
      "s3:GetStorage*",
      "s3:List*"
    ]
    resources = [
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}/common/*",
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}/common/"
    ]
  }
  statement {
    sid    = "AllowRootAndTopListing"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}",
      "arn:aws:s3:::login-gov.app-secrets.${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:prefix"
      values = [
        "common/",
        ""
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:delimiter"
      values = [
        "/"
      ]
    }
  }
  statement {
    sid    = "AllowSubListing"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}",
      "arn:aws:s3:::login-gov.app-secrets.${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
    ]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = [
        "common/"
      ]
    }
  }
  statement {
    sid    = "SoftwareArtifacts"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::login-gov-public-artifacts-${data.aws_region.current.name}",
      "arn:aws:s3:::login-gov-public-artifacts-${data.aws_region.current.name}/*"
    ]
  }
}

data "aws_iam_policy_document" "s3_artifacts_access" {
  statement {
    sid    = "S3ArtifactsAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::login-gov-public-artifacts-${data.aws_region.current.name}",
      "arn:aws:s3:::login-gov-public-artifacts-${data.aws_region.current.name}/*"
    ]
  }
}

resource "aws_iam_role_policy" "codebuild_packer_s3" {
  name   = "CodeBuildPackerS3Policy"
  role   = aws_iam_role.packer.name
  policy = data.aws_iam_policy_document.codebuild_packer_s3.json
}

resource "aws_iam_role_policy" "s3_artifacts_access" {
  name   = "S3ArtifactsAccess"
  role   = aws_iam_role.packer.name
  policy = data.aws_iam_policy_document.s3_artifacts_access.json
}

resource "aws_iam_role" "cloudwatch_events" {
  name               = "${var.name}-${data.aws_region.current.name}-${var.env_name}-cloudwatch-events"
  description        = "Allows AWS CloudWatch events to trigger the execution of the imagebuild pipeline via AWS CodePipeline."
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_events.json
}

data "aws_iam_policy_document" "cloudwatch_codepipeline" {
  statement {
    sid    = "CodePipeline"
    effect = "Allow"
    actions = [
      "codepipeline:StartPipelineExecution"
    ]
    resources = [
      aws_codepipeline.base_image.arn,
      aws_codepipeline.rails_image.arn
    ]
  }
}

resource "aws_iam_role_policy" "cloudwatch_codepipeline" {
  role   = aws_iam_role.cloudwatch_events.name
  name   = "CodePipeline"
  policy = data.aws_iam_policy_document.cloudwatch_codepipeline.json
}
