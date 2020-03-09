resource "aws_config_config_rule" "vpc-flow-logs-enabled" {
  name                        = "vpc-flow-logs-enabled"
  description                 = "Checks whether Amazon Virtual Private Cloud flow logs are found and enabled for Amazon VPC."
  maximum_execution_frequency = "One_Hour"
  source {
    owner             = "AWS"
    source_identifier = "VPC_FLOW_LOGS_ENABLED"
  }

}
resource "aws_config_config_rule" "cloud-trail-log-file-validation-enabled" {
  name                        = "cloud-trail-log-file-validation-enabled"
  description                 = "Checks whether AWS CloudTrail creates a signed digest file with logs. AWS recommends that the file validation must be enabled on all trails. The rule is noncompliant if the validation is not enabled."
  maximum_execution_frequency = "One_Hour"
  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_LOG_FILE_VALIDATION_ENABLED"
  }

}
resource "aws_config_config_rule" "cmk-backing-key-rotation-enabled" {
  name                        = "cmk-backing-key-rotation-enabled"
  description                 = "Checks that key rotation is enabled for each key and matches to the key ID of the customer created customer master key (CMK). The rule is compliant, if the key rotation is enabled for specific key object."
  maximum_execution_frequency = "TwentyFour_Hours"
  source {
    owner             = "AWS"
    source_identifier = "CMK_BACKING_KEY_ROTATION_ENABLED"
  }

}

resource "aws_config_config_rule" "guardduty-enabled-centralized" {
  name                        = "guardduty-enabled-centralized"
  description                 = "Checks whether Amazon GuardDuty is enabled in your AWS account and region. If you provide an AWS account for centralization, the rule evaluates the GuardDuty results in that account. The rule is compliant when GuardDuty is enabled."
  maximum_execution_frequency = "TwentyFour_Hours"
  source {
    owner             = "AWS"
    source_identifier = "GUARDDUTY_ENABLED_CENTRALIZED"
  }

}

resource "aws_config_config_rule" "encrypted-volumes" {
  name        = "encrypted-volumes"
  description = "Checks whether EBS volumes that are in an attached state are encrypted. Optionally, you can specify the ID of a KMS key to use to encrypt the volume."
  scope {
    compliance_resource_types = [
      "AWS::EC2::Volume"
    ]
  }
  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }

}

resource "aws_config_config_rule" "iam-root-access-key-check" {
  name                        = "iam-root-access-key-check"
  description                 = "Checks whether the root user access key is available. The rule is compliant if the user access key does not exist."
  maximum_execution_frequency = "One_Hour"
  source {
    owner             = "AWS"
    source_identifier = "IAM_ROOT_ACCESS_KEY_CHECK"
  }

}

resource "aws_config_config_rule" "iam-user-mfa-enabled" {
  name                        = "iam-user-mfa-enabled"
  description                 = "Checks whether the AWS Identity and Access Management users have multi-factor authentication (MFA) enabled."
  maximum_execution_frequency = "TwentyFour_Hours"
  source {
    owner             = "AWS"
    source_identifier = "IAM_USER_MFA_ENABLED"
  }

}

resource "aws_config_config_rule" "iam-user-unused-credentials-check" {
  name             = "iam-user-unused-credentials-check"
  description      = "Checks whether your AWS Identity and Access Management (IAM) users have passwords or active access keys that have not been used within the specified number of days you provided."
  input_parameters = <<EOP
    {
        "maxCredentialUsageAge" : 90
    }

    EOP

  maximum_execution_frequency = "TwentyFour_Hours"
  source {
    owner             = "AWS"
    source_identifier = "IAM_USER_UNUSED_CREDENTIALS_CHECK"
  }

}

resource "aws_config_config_rule" "rds-instance-public-access-check" {
  name        = "rds-instance-public-access-check"
  description = "Checks whether the Amazon Relational Database Service (RDS) instances are not publicly accessible. The rule is non-compliant if the publiclyAccessible field is true in the instance configuration item."
  scope {
    compliance_resource_types = [
      "AWS::RDS::DBInstance"
    ]
  }
  source {
    owner             = "AWS"
    source_identifier = "RDS_INSTANCE_PUBLIC_ACCESS_CHECK"
  }

}

resource "aws_config_config_rule" "rds-storage-encrypted" {
  name        = "rds-storage-encrypted"
  description = "Checks whether storage encryption is enabled for your RDS DB instances."
  scope {
    compliance_resource_types = [
      "AWS::RDS::DBInstance"
    ]
  }
  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }
}

resource "aws_config_config_rule" "root-account-mfa-enabled" {
  name                        = "root-account-mfa-enabled"
  description                 = "Checks whether the root user of your AWS account requires multi-factor authentication for console sign-in."
  maximum_execution_frequency = "One_Hour"
  source {
    owner             = "AWS"
    source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
  }
}

resource "aws_config_config_rule" "approved-amis-by-tag" {
  name             = "approved-amis-by-tag"
  description      = "Checks whether running instances are using specified AMIs. Specify the tags that identify the AMIs. Running instances with AMIs that don't have at least one of the specified tags are noncompliant."
  input_parameters = <<EOP
        {
        "amisByTagKeyAndValue" : "OS_Version:Ubuntu 18.04"
        }
    EOP
  scope {
    compliance_resource_types = [
      "AWS::EC2::Instance"
    ]
  }
  source {
    owner             = "AWS"
    source_identifier = "APPROVED_AMIS_BY_TAG"
  }
}

resource "aws_config_config_rule" "cloud-trail-encryption-enabled" {
  name                        = "cloud-trail-encryption-enabled"
  description                 = "Checks whether AWS CloudTrail is configured to use the server side encryption (SSE) AWS Key Management Service (AWS KMS) customer master key (CMK) encryption. The rule is compliant if the KmsKeyId is defined."
  maximum_execution_frequency = "TwentyFour_Hours"
  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENCRYPTION_ENABLED"
  }
}
