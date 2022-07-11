module "config_password_rotation" {
  source = "../../modules/config_iam_password_rotation"
  depends_on = [
    aws_sns_topic.slack_use1,
    aws_sns_topic.slack_usw2
  ]

  config_password_rotation_name = var.config_password_rotation_name
  region                        = var.region
  password_rotation_frequency   = var.password_rotation_frequency
  password_rotation_max_key_age = var.password_rotation_max_key_age
  config_password_rotation_code = "../../modules/config_iam_password_rotation/${var.config_password_rotation_code}"
  slack_events_sns_topic        = var.slack_events_sns_topic
}
