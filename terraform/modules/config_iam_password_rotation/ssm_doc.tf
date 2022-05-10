resource "aws_ssm_document" "config_password_rotation_ssm_doc" {
  name          = "${var.config_password_rotation_name}-automation-doc"
  document_type = "Automation"

  content = <<DOC
  {
    "schemaVersion": "0.3",
    "description": "Automation Document for sending notification to the SNS Topic",

    "assumeRole": "{{ AutomationAssumeRole }}",
    "parameters": {
    "AutomationAssumeRole": {
      "description": "(Optional) The ARN of the role that allows Automation to perform the actions on your behalf.",
      "type": "String"
    },
    "TopicArn": {
      "description": "(Required) The SNS Topic Name",
      "type": "String"
    },
    "Message": {
      "description": "Account not compliant",
      "type": "String"
    }
  },
    "mainSteps": [
    {
      "maxAttempts": 1,
      "inputs": {
          "TopicArn": "${data.aws_sns_topic.config_password_rotation_topic.arn}",
          "Message": "{{Message}}",
          "Api": "Publish",
          "Service": "sns"
      },
      "name": "PublishSNSNotification",
      "action": "aws:executeAwsApi",
      "timeoutSeconds": 30,
      "onFailure": "Abort"
    }
  ]
  }
DOC
}