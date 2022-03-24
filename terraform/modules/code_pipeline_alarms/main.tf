variable "alarm_name" {
  description = "Name used to create the Cloudwatch event rule"
  type        = string
}

variable "code_pipeline_arn" {
  description = "ARN of Code Pipeline to monitor"
  type        = string
}

variable "enable_autotf_alarms" {
  description = "enable/disable the autotf alarms"
  type        = bool
  default     = true
}

variable "sns_target_arn" {
  description = "An ARN to notify when the alarm fires"
  type        = string
}

resource "aws_cloudwatch_event_rule" "main" {
  name        = var.alarm_name
  count       = var.enable_autotf_alarms ? 1 : 0
  description = "Detects failures on ${var.alarm_name}"

  event_pattern = <<-EOF
    {
    "source": ["aws.codepipeline"],
      "detail-type": [
        "CodePipeline Pipeline Execution State Change",
        "CodePipeline Action Execution State Change",
        "CodePipeline Stage Execution State Change"
      ],
      "resources": ["${var.code_pipeline_arn}"],
      "detail": {
        "state": [
          "FAILED",
          "ABANDONED"
        ]
      }
    }
  EOF
}

resource "aws_cloudwatch_event_target" "sns" {
  count     = var.enable_autotf_alarms ? 1 : 0
  rule      = aws_cloudwatch_event_rule.main[0].name
  target_id = "SendToSNS"
  arn       = var.sns_target_arn
}
