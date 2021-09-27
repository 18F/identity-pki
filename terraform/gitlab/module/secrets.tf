# this policy can allow any node/host to access the s3 secrets bucket
data "aws_iam_policy_document" "secrets_role_policy" {
  statement {
    sid    = "AllowBucketAndObjects"
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*",
    ]

    # TODO: login-gov-secrets-test and login-gov-secrets are deprecated
    resources = [
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/common/",
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/common/*",
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/${var.env_name}/",
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/${var.env_name}/*",
    ]
  }

  # allow ls to work
  statement {
    sid    = "AllowRootAndTopListing"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:prefix"
      values   = ["", "common/", "${var.env_name}/"]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:delimiter"
      values   = ["/"]
    }
    resources = [
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*",
    ]
  }

  # allow subdirectory ls
  statement {
    sid    = "AllowSubListing"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["common/", "${var.env_name}/*"]
    }
    resources = [
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*",
    ]
  }

  # Allow notifying ASG lifecycle hooks. This isn't a great place for this
  # permission since not actually related, but it's useful to put here because
  # all of our ASG instances need it.
  statement {
    sid    = "AllowCompleteLifecycleHook"
    effect = "Allow"
    actions = [
      "autoscaling:CompleteLifecycleAction",
      "autoscaling:RecordLifecycleActionHeartbeat",
    ]
    resources = [
      "arn:aws:autoscaling:*:*:autoScalingGroup:*:autoScalingGroupName/${var.env_name}-*",
    ]
  }
}

data "aws_iam_policy_document" "common_secrets_role_policy" {
  statement {
    sid    = "AllowBucketAndObjects"
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*",
    ]

    resources = [
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/common/",
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/common/*"
    ]
  }

  # allow ls to work
  statement {
    sid    = "AllowRootAndTopListing"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:prefix"
      values   = ["", "common/", "${var.env_name}/"]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:delimiter"
      values   = ["/"]
    }
    resources = [
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*",
    ]
  }

  # allow subdirectory ls
  statement {
    sid    = "AllowSubListing"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["common/", "${var.env_name}/*"]
    }
    resources = [
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*",
    ]
  }

  # Allow notifying ASG lifecycle hooks. This isn't a great place for this
  # permission since not actually related, but it's useful to put here because
  # all of our ASG instances need it.
  statement {
    sid    = "AllowCompleteLifecycleHook"
    effect = "Allow"
    actions = [
      "autoscaling:CompleteLifecycleAction",
      "autoscaling:RecordLifecycleActionHeartbeat",
    ]
    resources = [
      "arn:aws:autoscaling:*:*:autoScalingGroup:*:autoScalingGroupName/${var.env_name}-*",
    ]
  }
}


# Role that instances can use to access stuff in citadel. Add this as the role
# for an aws_iam_instance_profile. Note that terraform < 0.9 has a "roles"
# attribute on aws_iam_instance_profile even though there is a 1:1 mapping
# between iam_instance_profiles and iam_roles.
resource "aws_iam_role" "citadel-client" {
  name               = "${var.env_name}-citadel-client"
  assume_role_policy = data.aws_iam_policy_document.assume_role_from_vpc.json
}

# Role policy that associates it with the secrets_role_policy
resource "aws_iam_role_policy" "citadel-client" {
  name   = "${var.env_name}-citadel-client"
  role   = aws_iam_role.citadel-client.id
  policy = data.aws_iam_policy_document.secrets_role_policy.json
}

# IAM instance profile using the citadel client role
resource "aws_iam_instance_profile" "citadel-client" {
  name = "${var.env_name}-citadel-client"
  role = aws_iam_role.citadel-client.name
}
