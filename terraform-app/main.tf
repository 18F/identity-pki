provider "aws" {
  version = "~> 1.17"
  region = "${var.region}"
}

# various version constraints
provider "external" {
    version = "~> 1.0"
}
provider "null" {
    version = "~> 1.0"
}
provider "template" {
    version = "~> 1.0"
}

# Stub remote config needed for terraform 0.9.*
terraform {
  backend "s3" {
  }
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
