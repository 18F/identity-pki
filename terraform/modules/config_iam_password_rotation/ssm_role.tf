data "aws_iam_policy_document" "config_password_rotation_ssm_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "config_password_rotation_remediation_role" {
  name               = "${var.config_password_rotation_name}-ssm-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.config_password_rotation_ssm_policy.json
}

data "aws_iam_policy_document" "config_password_rotation_ssm_access" {
  statement {
    sid       = "${local.passwordrotation_name_iam}ResourceAccess"
    effect    = "Allow"
    actions   = ["config:ListDiscoveredResources"]
    resources = ["*"]
  }
  statement {
    sid       = "${local.passwordrotation_name_iam}SNSAccess"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = ["${data.aws_sns_topic.config_password_rotation_topic.arn}"]
  }
}

resource "aws_iam_policy" "config_password_rotation_ssm_access" {
  name        = "${var.config_password_rotation_name}-ssm-policy"
  description = "Policy for ${var.config_password_rotation_name}-ssm access"
  policy      = data.aws_iam_policy_document.config_password_rotation_ssm_access.json
}

resource "aws_iam_role_policy_attachment" "config_password_rotation_remediation" {
  role       = aws_iam_role.config_password_rotation_remediation_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole"
}

resource "aws_iam_role_policy_attachment" "config_password_rotation_ssm_access" {
  role       = aws_iam_role.config_password_rotation_remediation_role.name
  policy_arn = aws_iam_policy.config_password_rotation_ssm_access.arn
}