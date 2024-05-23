resource "aws_cloudwatch_event_rule" "codebuild_failure" {
  count       = var.build_alarms_enable ? 1 : 0
  name        = "${var.name}-${data.aws_region.current.name}-${var.env_name}-imagebuild-failure"
  description = "Capture Codebuild Failure Events"

  event_pattern = jsonencode(
    {
      "source" : ["aws.codebuild"],
      "detail-type" : ["CodeBuild Build State Change"],
      "detail" : {
        "EventCategories" : ["FAILED"]
      },
      "resources" : [
        aws_codebuild_project.base_image.name,
        aws_codebuild_project.rails_image.name
      ]
    }
  )
}

resource "aws_cloudwatch_event_target" "codebuild_failure" {
  count     = var.build_alarms_enable ? 1 : 0
  rule      = aws_cloudwatch_event_rule.codebuild_failure[0].name
  target_id = "SendCodebuildFailOverEventsToSlackViaSNS"
  arn       = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.slack_events_sns_hook_name}"

  input_transformer {
    input_paths = {
      name          = "$.detail.project-name",
      region        = "$.region",
      time_of_issue = "$.time",
      deep-link     = "$.detail.additional-information.logs.deep-link",
    }
    input_template = "\"Imagebuild failed for <name> Region: <region> Time: <time_of_issue> Logs: <deep-link>\""
  }
}