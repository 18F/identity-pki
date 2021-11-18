data "aws_sns_topic" "config_access_key_rotation_topic" {
  name = local.sns_topic_name
}

resource "aws_sns_topic_subscription" "config_access_key_rotation_lambda_target" {
  topic_arn = data.aws_sns_topic.config_access_key_rotation_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.config_access_key_rotation_lambda.arn
}