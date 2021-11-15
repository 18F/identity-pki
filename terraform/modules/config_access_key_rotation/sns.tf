resource "aws_sns_topic_subscription" "config_access_key_rotation_lambda_target" {
  topic_arn = aws_sns_topic.config_access_key_rotation_topic.arn # adjust to the existing sns topic
  protocol  = "lambda"
  endpoint  = aws_lambda_function.config_access_key_rotation_lambda.arn
}