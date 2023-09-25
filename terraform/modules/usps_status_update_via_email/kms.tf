data "aws_iam_role" "worker" {
  name = "${var.env_name}_worker_iam_role"
}

resource "aws_kms_key" "usps" {
  description             = "KMS Key for USPS IPPaaS Email SNS Encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 10

  policy = <<EOF
  {
      "Id": "UspsKeyPolicy",
      "Version": "2012-10-17",
      "Statement": [{
            "Sid": "Allow SES to encrypt messages using this KMS key",
            "Effect": "Allow",
            "Principal": {
              "Service": "ses.amazonaws.com"
            },
            "Action": [
              "kms:Decrypt",
              "kms:GenerateDataKey*"
            ],
            "Resource": "*",
            "Condition": {
              "ArnLike": { 
                  "aws:SourceArn": "arn:aws:ses:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:receipt-rule-set/*:receipt-rule/usps-${var.env_name}-rule" 
              },
              "StringEquals": {
                  "aws:SourceAccount": "${data.aws_caller_identity.current.account_id}",
                  "kms:EncryptionContext:aws:sns:topicArn": "${aws_sns_topic.usps_topic.arn}" 
              }
            }
          },
          {
            "Sid": "Allow SNS to encrypt messages using this KMS key",
            "Effect": "Allow",
            "Principal": {
              "Service": "sns.amazonaws.com"
            },
            "Action": [
              "kms:Decrypt",
              "kms:GenerateDataKey*"
            ],
            "Resource": "*",
            "Condition": {
              "StringEquals": {
                  "aws:SourceArn": "${aws_sns_topic.usps_topic.arn}",
                  "kms:EncryptionContext:aws:sqs:arn": "${aws_sqs_queue.usps.arn}" 
              }
            }
          },
          {
            "Sid": "Allow access for queue consumers",
            "Effect": "Allow",
            "Action": [
                "kms:Decrypt"
            ],
            "Principal": {
              "AWS": "${data.aws_iam_role.worker.arn}"
            },
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

resource "aws_kms_alias" "usps" {
  target_key_id = aws_kms_key.usps.key_id
  name          = local.aws_kms_key_alias
}
