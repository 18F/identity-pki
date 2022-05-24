output "ta_monitor_lambda_arn" {
  value       = aws_lambda_function.ta_monitor_lambda.arn
  description = "TA Monitor Lambda function arn"
}
output "ta_refresher_lambda_arn" {
  value       = aws_lambda_function.ta_refresher_lambda.arn
  description = "TA Refresher Lambda function arn"
}

