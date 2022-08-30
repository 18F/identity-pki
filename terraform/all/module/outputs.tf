output "region" {
  value = var.region
}

output "sns_to_slack_use1" {
  value = aws_sns_topic.slack_use1
}

output "sns_to_slack_usw2" {
  value = aws_sns_topic.slack_usw2
}

output "config_password_rotation_code" {
  value = var.config_password_rotation_code
}

output "config_password_rotation_name" {
  value = var.config_password_rotation_name
}