# Enforce Specific KMS ARN

This is a block that we can enable in the future to enforce a specific KMS ARN,
so that everything uploaded to the bucket is encrypted with a specific KMS key.
This would be useful, for example, for knowing that everything uploaded to our
prod s3 bucket is encrypted with the prod KMS key.

    variable "kms_key_id" {
        description = "Key to use for KMS decryption"
    }

    # This is effectively a local variable called "kms_arn", and is a workaround to
    # the fact that terraform doesn't support local variables.  See:
    # https://github.com/hashicorp/terraform/issues/4084#issuecomment-176909372
    resource "null_resource" "kms_arn" {
    count = "${var.use_kms == true ? 1 : 0}"
    triggers = {
        kms_arn = "arn:aws:kms:${var.region}:${data.aws_caller_identity.current.account_id}:key/${var.kms_key_id}"
    }
    }

    resource "aws_s3_bucket_policy" "kms_encryption_policy" {
    count = "${var.use_kms == true ? 1 : 0}"
    bucket = "${aws_s3_bucket.secrets.id}"
    policy = <<EOF
    {
    "Version":"2012-10-17",
    "Id":"PutObjPolicy-${aws_s3_bucket.secrets.id}",
    "Statement":[{
        "Sid":"DenyUnEncryptedObjectUploads",
        "Effect":"Deny",
        "Principal":"*",
        "Action":"s3:PutObject",
        "Resource":"arn:aws:s3:::${aws_s3_bucket.secrets.id}/*",
        "Condition":{
        "StringNotEquals":{
            "s3:x-amz-server-side-encryption":"aws:kms",
            "s3:x-amz-server-side-encryption-aws-kms-key-id":"${null_resource.kms_arn.triggers.kms_arn}"
        }
        }
    }]
    }
    EOF
    }
