output "config_access_key_rotation_role" {
  description = "The IAM Role that was created"
  value       = "${aws_iam_role.config_access_key_rotation_remediation_role.arn}"
}

output "config_access_key_rotation_ssm_doc" {
  description = "The System Manager Automation Document that was created"
  value       = "${aws_ssm_document.config_access_key_rotation_ssm_doc.name}"
}

output "config_access_key_rotation_rule" {
  description = "The AWS Config Rule that was enabled"
  value       = "${aws_config_config_rule.config_access_key_rotation_rule.name}"
}

output "config_access_key_rotation_topic" {
  description = "The SNS Topic that was created"
  value       = "${aws_sns_topic.config_access_key_rotation_topic.arn}"
}