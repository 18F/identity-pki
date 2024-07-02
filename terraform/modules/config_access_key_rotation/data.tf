data "aws_sns_topic" "alarm_targets" {
  for_each = var.alarm_sns_topics

  name = each.key
}
