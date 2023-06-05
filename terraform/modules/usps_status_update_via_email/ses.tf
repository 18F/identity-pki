data "aws_region" "current" {}

resource "aws_ses_domain_identity" "usps" {
  domain = aws_route53_zone.usps_zone.name
}

resource "aws_ses_domain_identity_verification" "usps_ses_verif" {
  domain = aws_ses_domain_identity.usps.id

  depends_on = [aws_route53_record.usps_ses_verify]
}

resource "aws_sns_topic_subscription" "usps_updates_sqs" {
  topic_arn           = aws_sns_topic.usps_topic.arn
  protocol            = "sqs"
  endpoint            = aws_sqs_queue.usps.arn
  filter_policy_scope = "MessageBody"

  # See documentation here:
  # https://docs.aws.amazon.com/ses/latest/dg/receiving-email-notifications-contents.html
  filter_policy = jsonencode(merge(
    {
      receipt = {
        spfVerdict = {
          status = ["PASS"]
        }
        dkimVerdict = {
          status = ["PASS"]
        }
      }
    },
    length(var.allowed_source_email_addresses) > 0 ? {
      mail = {
        source = var.allowed_source_email_addresses
      }
    } : {}
  ))

}
