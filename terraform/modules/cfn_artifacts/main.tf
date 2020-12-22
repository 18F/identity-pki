variable "region" {
  default = "us-west-2"
}

variable "artifact_bucket" {
  default = ""
}

variable "git2s3_stack_name" {
  default = ""
}

variable "prod_account_id" {
  default = ""
}

data "aws_cloudformation_stack" "git2s3" {
  name = var.git2s3_stack_name
}

resource "aws_s3_bucket_policy" "policy" {
  bucket = var.artifact_bucket
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${var.prod_account_id}:root"
            },
            "Action": [
                "s3:Get*",
                "s3:List*"
            ],
            "Resource": [
                "arn:aws:s3:::${var.artifact_bucket}/*"
            ]
        }
    ]
}
POLICY
}

resource "aws_s3_bucket_object" "git2s3_output_bucket_name" {
  bucket = var.artifact_bucket
  key = "git2s3/OutputBucketName"
  source = data.aws_cloudformation_stack.git2s3.outputs["OutputBucketName"]
  content_type = "text/plain"
}

output "output_bucket" {
  value = aws_s3_bucket_object.git2s3_output_bucket_name.key
}
