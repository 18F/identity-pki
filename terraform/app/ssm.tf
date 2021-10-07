# Policy and roles to permit SSM access / actions on EC2 instances, and to allow them to send metrics and logs to CloudWatch

data "aws_iam_policy_document" "ssm_access_role_policy" {
  statement {
    sid = "SSMCoreAccess"
    actions = [
      "ssm:DescribeAssociation",
      "ssm:GetDeployablePatchSnapshotForInstance",
      "ssm:GetDocument",
      "ssm:DescribeDocument",
      "ssm:GetManifest",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:ListAssociations",
      "ssm:ListInstanceAssociations",
      "ssm:PutInventory",
      "ssm:PutComplianceItems",
      "ssm:PutConfigurePackageResult",
      "ssm:UpdateAssociationStatus",
      "ssm:UpdateInstanceAssociationStatus",
      "ssm:UpdateInstanceInformation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
      "ec2messages:AcknowledgeMessage",
      "ec2messages:DeleteMessage",
      "ec2messages:FailMessage",
      "ec2messages:GetEndpoint",
      "ec2messages:GetMessages",
      "ec2messages:SendReply",
    ]

    resources = [
      "*",
    ]
  }
  statement {
    sid = "CloudWatchAgentAccess"
    actions = [
      "cloudwatch:PutMetricData",
      "ec2:DescribeVolumes",
      "ec2:DescribeTags",
    ]

    resources = [
      "*",
    ]
  }
  statement {
    sid = "CloudWatchLogsAccess"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
    ]

    resources = [
      "*"
    ]
  }
}

# Base role required for all instances
resource "aws_iam_role" "ssm-access" {
  name               = "${var.env_name}-ssm-access"
  assume_role_policy = data.aws_iam_policy_document.assume_role_from_vpc.json
}

# Role policy that associates it with the ssm_access_role_policy
resource "aws_iam_role_policy" "ssm-access" {
  name   = "${var.env_name}-ssm-access"
  role   = aws_iam_role.ssm-access.id
  policy = data.aws_iam_policy_document.ssm_access_role_policy.json
}

# IAM instance profile using the ssm-access role
resource "aws_iam_instance_profile" "ssm-access" {
  name = "${var.env_name}-ssm-access"
  role = aws_iam_role.ssm-access.name
}

resource "aws_ssm_document" "ssm-document-gsa-username" {
  name          = "${var.env_name}-ssm-document-gsa-username"
  document_type = "Session"

  version_name = "1.0.0"
  target_type  = "/AWS::EC2::Instance"

  document_format = "YAML"
  content         = <<DOC
---
schemaVersion: '1.0'
description: SSM session user GSA_USERNAME
sessionType: InteractiveCommands
parameters:
  gsausername: # not allowed to have underscores :[
    type: String
    description: The GSA_USERNAME of the person calling the script.
    allowedPattern: "^[a-zA-Z0-9-_/]+$"
properties:
  linux:
    commands: "GSA_USERNAME={{ gsausername }} /bin/bash"
    runAsElevated: false
  DOC
}