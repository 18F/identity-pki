output "ses_feedback_eval_lambda_loggroup" {
  value = aws_cloudwatch_log_group.ses_lambda_cw_logs.name
}

output "sns_for_ses_bounce_notifications" {
  value = aws_sns_topic.ses_feedback_topic_bounce.arn
}

output "sns_for_ses_compliant_notifications" {
  value = aws_sns_topic.ses_feedback_topic_complaint.arn
}

output "sns_for_ses_delivery_notifications" {
  value = aws_sns_topic.ses_feedback_topic_delivery.arn
}