provider "aws" {
  region = "${var.region}"
  version = "~> 1.60"
}

provider "aws" {
  region = "us-east-1"
  alias = "use1"
}

provider "aws" {
  alias = "usw2"
  region = "${var.region}"
}

provider "external" { version = "~> 1.0" }
provider "null"     { version = "~> 1.0" }
provider "template" { version = "~> 1.0" }

# Stub remote config needed for terraform 0.9.*
terraform {
  backend "s3" {
  }

  # Allowed terraform version
  required_version = "~> 0.11.7"
}

# This policy can be used to allow anybody to join the role
data "aws_iam_policy_document" "assume_role_from_vpc" {
  statement {
    sid = "allowVPC"
    actions = [
      "sts:AssumeRole"
    ]
    principals = {
      type = "Service"
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
      "logs:DescribeLogStreams"
    ]
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}
