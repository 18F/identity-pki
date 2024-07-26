resource "aws_cloudwatch_event_rule" "incident_opened" {
  name          = "IncidentManagerIncidentOpened"
  description   = "An incident has been opened"
  event_pattern = <<EOF
{
  "source": ["aws.ssm-incidents"],
  "detail": {
    "eventName": ["StartIncident"]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "incident_opened" {
  rule = aws_cloudwatch_event_rule.incident_opened.name
  arn  = var.slack_notification_arn

  input_transformer {
    input_paths = {
      title = "$.detail.requestParameters.title",
    }
    input_template = "{\"IncidentManagerEvent\" : \"IncidentOpened\",\"Details\" : {\"title\": <title>}}"
  }
}

resource "aws_cloudwatch_event_rule" "incident_closed" {
  name          = "IncidentManagerIncidentClosed"
  description   = "The incident has been closed"
  event_pattern = <<EOF
{
  "source": ["ssm-incidents.amazonaws.com"],
  "detail": {
    "eventName": ["UpdateIncidentRecord"],
    "requestParameters": {
        "status": ["RESOLVED"]
    }
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "incident_closed" {
  rule = aws_cloudwatch_event_rule.incident_closed.name
  arn  = var.slack_notification_arn

  input_transformer {
    input_paths = {
      title = "$.detail.requestParameters.title",
    }
    input_template = "{\"IncidentManagerEvent\" : \"IncidentClosed\",\"Details\" : {\"title\": <title>}}"
  }
}

resource "aws_cloudwatch_event_rule" "responder_paged" {
  name          = "IncidentManagerResponderPaged"
  description   = "The responder has been paged"
  event_pattern = <<EOF
{
  "source": ["aws.ssm-incidents"],
  "detail": {
    "eventName": ["CreateTimelineEvent"],
    "requestParameters": {
        "eventType": ["SSM Contacts Page for Incident"]
    }
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "responder_paged" {
  rule = aws_cloudwatch_event_rule.responder_paged.name
  arn  = var.slack_notification_arn

  input_transformer {
    input_paths = {
      event_data = "$.detail.requestParameters.eventData",
    }
    input_template = "{\"IncidentManagerEvent\": \"ResponderPaged\",\"Details\": {\"eventData\": <event_data>}}"
  }
}

resource "aws_cloudwatch_event_rule" "responder_acknowledged" {
  name          = "IncidentManagerResponderAcknowledged"
  description   = "The responder has acknowledged the page"
  event_pattern = <<EOF
{
  "source": ["aws.ssm-incidents"],
  "detail": {
    "eventName": ["CreateTimelineEvent"],
    "requestParameters": {
        "eventType": ["SSM Contacts Page Acknowledgement for Incident"]
    }
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "responder_acknowledged" {
  rule = aws_cloudwatch_event_rule.responder_acknowledged.name
  arn  = var.slack_notification_arn

  input_transformer {
    input_paths = {
      event_data = "$.detail.requestParameters.eventData",
    }
    input_template = "{\"IncidentManagerEvent\": \"ResponderAcknowledged\",\"Details\":  {\"eventData\": <event_data>}}"
  }
}
