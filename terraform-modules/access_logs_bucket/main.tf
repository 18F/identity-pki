data "aws_caller_identity" "current" {}

# To give ELBs the ability to upload logs to an S3 bucket, we need to create a
# policy that gives permission to a magical AWS account ID to upload logs to our
# bucket, which differs by region.  This table contaings those mappings, and was
# taken from:
# http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-access-logs.html
# Also see:
# https://github.com/hashicorp/terraform/pull/3756/files
# For the PR when ELB access logs were added in terraform to see an example of
# the supported test cases for this ELB to S3 logging configuration.
variable "elb_account_ids" {
    type = "map"
    description = "Mapping of region to ELB account ID"
    default = {
        us-east-1 = "127311923021"
        us-east-2 = "033677994240"
        us-west-1 = "027434742980"
        us-west-2 = "797873946194"
        ca-central-1 = "985666609251"
        eu-west-1 = "156460612806"
        eu-central-1 = "054676820928"
        eu-west-2 = "652711504416"
        ap-northeast-1 = "582318560864"
        ap-northeast-2 = "600734575887"
        ap-southeast-1 = "114774131450"
        ap-southeast-2 = "783225319266"
        ap-south-1 = "718504428378"
        sa-east-1 = "507241528517"
        us-gov-west-1 = "048591011584"
        cn-north-1 = "638102146993"
    }
}

resource "aws_s3_bucket" "logs" {
  bucket = "${var.bucket_name_prefix}.elb-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
  acl    = "log-delivery-write"
  force_destroy = "${var.force_destroy}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "Policy1503676948878",
  "Statement": [
    {
      "Sid": "Stmt1503676946489",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${lookup(var.elb_account_ids, var.region)}:root"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${var.bucket_name_prefix}.elb-logs.${data.aws_caller_identity.current.account_id}-${var.region}/${var.use_prefix_for_permissions ? join("/",list(var.log_prefix,"AWSLogs",data.aws_caller_identity.current.account_id,"*")) : "*"}"
    }
  ]
}
EOF

  tags {
    Environment = "All"
  }

  # In theory we should only put one copy of every file, so I don't think this
  # will increase space, just give us history in case we accidentally
  # delete/modify something.
  versioning {
    enabled = true
  }
}
