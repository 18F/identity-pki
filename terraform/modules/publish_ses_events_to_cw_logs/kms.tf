resource "aws_kms_key" "sqs_key" {
  description             = "KMS Keys for SQS queue Encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 10

  tags = {
    Name = "SQS_Key"
  }

  policy = <<EOF
  {
      "Id": "sqs-1",
      "Version": "2012-10-17",
      "Statement": [{
              "Sid": "Allow access through Simple Queue Service (SQS) for all principals in the account that are authorized to use SQS",
              "Effect": "Allow",
              "Principal": {
                  "AWS": "*"
              },
              "Action": [
                  "kms:Encrypt",
                  "kms:Decrypt",
                  "kms:ReEncrypt*",
                  "kms:GenerateDataKey*",
                  "kms:CreateGrant",
                  "kms:DescribeKey"
              ],
              "Resource": "*",
              "Condition": {
                  "StringEquals": {
                      "kms:ViaService": "sqs.${var.region}.amazonaws.com",
                      "kms:CallerAccount": "data.aws_caller_identity.current.account_id"
                  }
              }
          },
          {
              "Sid": "Allow access to lambda to decrypt messages when reading from SQS queue",
              "Effect": "Allow",
              "Principal": {
                  "AWS": "*"
              },
              "Action": [
                  "kms:Decrypt",
                  "kms:GenerateDataKey*",
                  "kms:DescribeKey"
              ],
              "Resource": "*",
              "Condition": {
                  "StringEquals": {
                      "kms:ViaService": "lambda.${var.region}.amazonaws.com",
                      "kms:CallerAccount": "data.aws_caller_identity.current.account_id"
                  }
              }
          },
          {
            "Sid": "Allow access through Simple Notification Service (SNS) for all principals in the account that are authorized to use SQS",
            "Effect": "Allow",
            "Principal": {
                "Service": "sns.amazonaws.com"
            },
            "Action": [
                "kms:Decrypt",
                "kms:GenerateDataKey*"
            ],
            "Resource": "*"
        },
          {
              "Sid": "Allow access for Key Administrators",
              "Effect": "Allow",
              "Principal": {
                  "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/FullAdministrator"
              },
              "Action": [
                  "kms:Update*",
                  "kms:UntagResource",
                  "kms:TagResource",
                  "kms:ScheduleKeyDeletion",
                  "kms:Revoke*",
                  "kms:Put*",
                  "kms:List*",
                  "kms:Get*",
                  "kms:Enable*",
                  "kms:Disable*",
                  "kms:Describe*",
                  "kms:Delete*",
                  "kms:Create*",
                  "kms:CancelKeyDeletion"
              ],
              "Resource": "*"
          },
          {
              "Sid": "Allow direct access to key metadata to the account",
              "Effect": "Allow",
              "Principal": {
                  "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
              },
              "Action": "kms:*",
              "Resource": "*"
          }
      ]
  }
  EOF
}

resource "aws_kms_alias" "my_kms_alias" {
  target_key_id = aws_kms_key.sqs_key.key_id
  name          = "alias/${local.verified_identity_alnum}-ses-kms-key"
}