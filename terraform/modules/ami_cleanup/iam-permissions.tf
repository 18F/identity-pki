data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ami_cleanup_lambda_assume" {
  statement {
    sid = "Assume"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ami_cleanup_lambda_cloudwatch_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "${aws_cloudwatch_log_group.ami_cleanup_log_group.arn}:*"
    ]
  }
}

resource "aws_iam_role" "lambda_ami_cleanup" {
  name_prefix = "lambda_ami_cleanup"

  assume_role_policy = data.aws_iam_policy_document.ami_cleanup_lambda_assume.json
}

resource "aws_iam_role_policy" "ami_cleanup_cloudwatch" {
  name = "CloudWatch"
  role = aws_iam_role.lambda_ami_cleanup.id
  policy = data.aws_iam_policy_document.ami_cleanup_lambda_cloudwatch_policy.json
}

data "aws_iam_policy_document" "ami_cleanup_lambda_Tag_policy" {
  statement {
    sid = "VisualEditor0"
    effect = "Allow"
    actions = [
      "ec2:CreateTags",
    ]
    resources = [
      "arn:aws:ec2:*::image/*"
    ]
  }
}

resource "aws_iam_role_policy" "ami_cleanup_tags" {
  name = "CreateTag"
  role = aws_iam_role.lambda_ami_cleanup.id
  policy = data.aws_iam_policy_document.ami_cleanup_lambda_Tag_policy.json
}

data "aws_iam_policy_document" "ami_cleanup_lambda_delete_snapshot_policy" {
  statement {
    sid = "VisualEditor0"
    effect = "Allow"
    actions = [
      "ec2:DeleteSnapshot",
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy" "ami_cleanup_delete_snapshot" {
  name = "DeleteSnapshot"
  role = aws_iam_role.lambda_ami_cleanup.id
  policy = data.aws_iam_policy_document.ami_cleanup_lambda_delete_snapshot_policy.json
}


data "aws_iam_policy_document" "ami_cleanup_lambda_deregister_image_policy" {
  statement {
    sid = "VisualEditor0"
    effect = "Allow"
    actions = [
      "ec2:DeregisterImage",
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy" "ami_cleanup_deregister_image" {
  name = "DeregisterImage"
  role = aws_iam_role.lambda_ami_cleanup.id
  policy = data.aws_iam_policy_document.ami_cleanup_lambda_deregister_image_policy.json
}

data "aws_iam_policy_document" "ami_cleanup_lambda_describe_image_policy" {
  statement {
    sid = "VisualEditor0"
    effect = "Allow"
    actions = [
      "ec2:DescribeImages",
      "ec2:DescribeImageAttribute",
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy" "ami_cleanup_describe_image" {
  name = "DescribeImageAttribute"
  role = aws_iam_role.lambda_ami_cleanup.id
  policy = data.aws_iam_policy_document.ami_cleanup_lambda_describe_image_policy.json
}

data "aws_iam_policy_document" "ami_cleanup_lambda_read_autoscaling_policy" {
  statement {
    sid = "VisualEditor0"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy" "ami_cleanup_read_autoscaling" {
  name = "ReadAutoscaling"
  role = aws_iam_role.lambda_ami_cleanup.id
  policy = data.aws_iam_policy_document.ami_cleanup_lambda_read_autoscaling_policy.json
}
