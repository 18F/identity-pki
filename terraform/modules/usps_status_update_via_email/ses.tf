data "aws_region" "current" {}

resource "aws_ses_domain_identity" "usps" {
  domain = aws_route53_zone.usps_zone.name
}

resource "aws_ses_domain_identity_verification" "usps_ses_verif" {
  domain = aws_ses_domain_identity.usps.id

  depends_on = [aws_route53_record.usps_ses_verify]
}

resource "aws_sns_topic_subscription" "usps_updates_sqs" {
  topic_arn = aws_sns_topic.usps_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.usps.arn
}
