resource "aws_config_config_rule" "config_access_key_rotation_rule" {
  name        = "${var.config_access_key_rotation_name}-rule"
  description = <<EOF
    "Checks whether the active access keys are rotated within the number of
    days specified in maxAccessKeyAge. The rule is non-compliant if the
    access keys have not been rotated for more than maxAccessKeyAge number
    of days."
  EOF

  input_parameters = jsonencode(
    {
      maxAccessKeyAge = "${var.config_access_key_rotation_max_key_age}"
    }
  )

  source {
    owner             = "AWS"
    source_identifier = "ACCESS_KEYS_ROTATED"
  }

  maximum_execution_frequency = var.config_access_key_rotation_frequency
}

resource "aws_config_remediation_configuration" "config_access_key_rotation_remediation" {
  config_rule_name           = aws_config_config_rule.config_access_key_rotation_rule.name
  resource_type              = "AWS::IAM::User"
  target_type                = "SSM_DOCUMENT"
  target_id                  = aws_ssm_document.config_access_key_rotation_ssm_doc.name
  automatic                  = true
  maximum_automatic_attempts = 1
  retry_attempt_seconds      = 43200

  parameter {
    name         = "AutomationAssumeRole"
    static_value = aws_iam_role.config_access_key_rotation_remediation_role.arn
  }
  parameter {
    name           = "ResourceId"
    resource_value = "RESOURCE_ID"
  }
}
