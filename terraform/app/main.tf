provider "aws" {
  region  = var.region
  version = "~> 2.43.0"
}

provider "aws" {
  region = "us-east-1"
  alias  = "use1"
}

provider "aws" {
  alias  = "usw2"
  region = var.region
}

provider "external" {
  version = "~> 1.2.0"
}

provider "null" {
  version = "~> 2.1.2"
}

provider "template" {
  version = "~> 2.1.2"
}

terraform {
  backend "s3" {
  }
  required_version = ">= 0.12"
}

data "aws_caller_identity" "current" {
}

# This policy can be used to allow the EC2 service to assume the role.
data "aws_iam_policy_document" "assume_role_from_vpc" {
  statement {
    sid = "allowVPC"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

#This policy is for writing log files to CloudWatch
data "aws_iam_policy_document" "cloudwatch-logs" {
  statement {
    sid = "allowCloudWatch"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
    ]
    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }
}

#This policy allows the CloudWatch agent to put metrics.
#Also requires the cloudwatch-logs policy
#Based on the AWS managed policy CloudWatchAgentServerPolicy
data "aws_iam_policy_document" "cloudwatch-agent" {
  statement {
    sid = "allowCloudWatchAgent"
    actions = [
      "cloudwatch:PutMetricData",
      "ec2:DescribeVolumes",
      "ec2:DescribeTags",
    ]
    resources = [
      "*",
    ]
  }
}
