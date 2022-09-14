output "ses_feedback_eval_lambda_loggroup" {
  value = aws_cloudwatch_log_group.ses_lambda_cw_logs.name
}