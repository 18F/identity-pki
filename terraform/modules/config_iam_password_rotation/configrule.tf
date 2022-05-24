resource "aws_config_config_rule" "config_password_rotation_rule" {
  name        = "${var.config_password_rotation_name}-config-rule"
  description = <<EOF
    "Checks whether the account password policy for IAM users meets the specified requirements."
  EOF

  input_parameters = jsonencode(
    {
      MaxPasswordAge = "${var.password_rotation_max_key_age}"
    }
  )

  source {
    owner             = "AWS"
    source_identifier = "IAM_PASSWORD_POLICY"
  }

  maximum_execution_frequency = var.password_rotation_frequency
}

resource "aws_config_remediation_configuration" "config_password_rotation_remediation" {
  config_rule_name = aws_config_config_rule.config_password_rotation_rule.name

  target_type                = "SSM_DOCUMENT"
  target_id                  = aws_ssm_document.config_password_rotation_ssm_doc.name
  automatic                  = true
  maximum_automatic_attempts = 2
  retry_attempt_seconds      = 600

  parameter {
    name         = "AutomationAssumeRole"
    static_value = aws_iam_role.config_password_rotation_remediation_role.arn
  }
  parameter {
    name         = "TopicArn"
    static_value = data.aws_sns_topic.config_password_rotation_topic.arn
  }
  parameter {
    name         = "Message"
    static_value = "Account is not compliant with the password policy."
  }
}