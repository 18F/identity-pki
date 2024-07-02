module "config_access_key_rotation" {
  source = "../../modules/config_access_key_rotation"

  config_access_key_rotation_name = var.config_access_key_rotation_name
  config_access_key_rotation_code = var.config_access_key_rotation_code
  alarm_sns_topics                = [aws_sns_topic.slack_usw2["alarms"].name]
}
