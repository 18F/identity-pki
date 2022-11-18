output "ses_events_eval_lambda_loggroup" {
  value = aws_cloudwatch_log_group.ses_events_lambda_cw_logs.name
}
