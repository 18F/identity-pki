# -- Variables --
variable "lambda_bucket" {
  description = "Name of the lambda-functions bucket in this account/region."
}

variable "circleci_arn" {
  description = "ARN of the CircleCI IAM user."
}

# -- Resources --

resource "aws_s3_bucket_policy" "lambda-functions" {
  bucket = var.lambda_bucket
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCircleCIPuts",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${var.circleci_arn}"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${var.lambda_bucket}/circleci/*"
    }
  ]
}
POLICY
}
