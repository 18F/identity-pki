locals {
  verified_identity_alnum = join("", regexall("[a-z]+", var.ses_verified_identity))
}

resource "aws_ses_configuration_set" "all_events" {
  name = "${local.verified_identity_alnum}-configset"

  delivery_options {
    tls_policy = var.tls_policy_requirement
  }
}

resource "aws_ses_event_destination" "sns" {
  name                   = "${local.verified_identity_alnum}-event-destination-sns"
  configuration_set_name = aws_ses_configuration_set.all_events.name
  enabled                = true
  matching_types         = ["send", "reject", "bounce", "complaint", "delivery", "renderingFailure"]

  sns_destination {
    topic_arn = aws_sns_topic.ses_events.arn
  }
}

resource "aws_sns_topic" "ses_events" {
  name = "${local.verified_identity_alnum}-ses-events"
}
