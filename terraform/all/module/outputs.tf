output "region" {
  value = var.region
}

output "sns_to_slack_use1" {
  value = aws_sns_topic.slack_use1
}

output "sns_to_slack_usw2" {
  value = aws_sns_topic.slack_usw2
}

output "splunk_oncall_sns_arns" {
  description = "ARN of the SNS topics for Splunk OnCall notification"
  value       = flatten([module.splunk_oncall_sns.usw2_sns_topic_arns, module.splunk_oncall_sns.use1_sns_topic_arns])
}

output "config_password_rotation_code" {
  value = var.config_password_rotation_code
}

output "config_password_rotation_name" {
  value = var.config_password_rotation_name
}
