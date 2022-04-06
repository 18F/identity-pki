resource "aws_cloudwatch_event_rule" "main" {
  name        = var.alarm_name
  description = "Detects Critical Scan Findings on ECR Using Inspector2"

  event_pattern = <<-EOF
    {
      "detail": {
        "packageVulnerabilityDetails": {
          "vendorSeverity": ["CRITICAL"]
        }
      },
      "detail-type": ["Inspector2 Finding"],
      "source": ["aws.inspector2"]
    }
  EOF
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.main.name
  target_id = "SendToSNS"
  arn       = var.sns_target_arn
}
