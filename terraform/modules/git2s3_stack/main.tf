variable "region" {
  default = "us-west-2"
}

variable "artifact_bucket" {
  default = ""
}

variable "git2s3_stack_name" {
  default = ""
}

variable "external_account_ids" {
  default = []
}

locals {
  git2s3_output_bucket = chomp(aws_cloudformation_stack.git2s3.outputs["OutputBucketName"])
}

data "github_ip_ranges" "ips" {
}

resource "aws_cloudformation_stack" "git2s3" {
  name          = "CodeSync-IdentityBaseImage"
  template_body = file("${path.module}/git2s3.template")
  parameters    = {
    AllowedIps          = data.github_ip_ranges.ips.git
    QSS3BucketName      = "aws-quickstart"
    OutputBucketName    = ""
    ScmHostnameOverride = ""
    ExcludeGit          = "True"
    VPCId               = ""
    CustomDomainName    = ""
    QSS3BucketRegion    = "us-east-1"
    ApiSecret           = ""
    QSS3KeyPrefix       = "quickstart-git2s3/"
    VPCCidrRange        = ""
    SubnetIds           = ""
  }
  capabilities = ["CAPABILITY_IAM"]
}

data "aws_iam_policy_document" "git2s3_output_bucket" {
  statement {
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = formatlist("arn:aws:iam::%s:root", var.external_account_ids)
    }
    actions = [
      "s3:Get*",
      "s3:List*"
    ]
    resources = [
      "arn:aws:s3:::${local.git2s3_output_bucket}",
      "arn:aws:s3:::${local.git2s3_output_bucket}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "git2s3_output_bucket" {
  bucket = local.git2s3_output_bucket
  policy = data.aws_iam_policy_document.git2s3_output_bucket.json
}

data "aws_iam_policy_document" "artifact_bucket" {
  statement {
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = formatlist("arn:aws:iam::%s:root", var.external_account_ids)
    }
    actions = [
      "s3:Get*",
      "s3:List*"
    ]
    resources = [
      "arn:aws:s3:::${var.artifact_bucket}",
      "arn:aws:s3:::${var.artifact_bucket}/*"
    ]
  }
  statement {
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = formatlist("arn:aws:iam::%s:root", var.external_account_ids)
    }
    actions = [
      "s3:Put*",
      "s3:Delete*",
    ]
    resources = [
      "arn:aws:s3:::${var.artifact_bucket}/packer_config/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "artifact_bucket" {
  bucket = var.artifact_bucket
  policy = data.aws_iam_policy_document.artifact_bucket.json
}

resource "aws_s3_bucket_object" "git2s3_output_bucket_name" {
  bucket       = var.artifact_bucket
  key          = "git2s3/OutputBucketName"
  content      = local.git2s3_output_bucket
  content_type = "text/plain"
}

output "output_bucket" {
  value = aws_s3_bucket_object.git2s3_output_bucket_name.key
}
