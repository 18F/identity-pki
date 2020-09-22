terraform {
  backend "s3" {}
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 2.67.0"
    }
    external = {
      source = "hashicorp/external"
      version = "~> 1.2.0"
    }
    github = {
      source = "hashicorp/github"
      version = "~> 2.9"
    }
    null = {
      source = "hashicorp/null"
      version = "~> 2.1.2"
    }
    template = {
      source = "hashicorp/template"
      version = "~> 2.1.2"
    }
  }
  required_version = ">= 0.13"
}

provider "aws" {
  region  = var.region
}

provider "aws" {
  region = "us-east-1"
  alias  = "use1"
}

provider "aws" {
  alias  = "usw2"
  region = var.region
}

data "github_ip_ranges" "ips" {
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

# Allow publishing to SNS topics used for alerting
#This policy is for writing log files to CloudWatch
data "aws_iam_policy_document" "sns-publish-alerts-policy" {
  statement {
    sid = "allowSNSPublish"
    actions = [
      "SNS:Publish",
    ]
    resources = [
      var.slack_events_sns_hook_arn,
    ]
  }
}
