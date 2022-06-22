# Hack to allow email-based SNS subscription creation in Terraform using CloudFormation:
# https://medium.com/@raghuram.arumalla153/aws-sns-topic-subscription-with-email-protocol-using-terraform-ed05f4f19b73

variable "sns_subscription_email_address_list" {
  description = "List of email addresses"
  type        = list(string)
}

variable "sns_subscription_protocol" {
  description = "SNS subscription protocol (must be left 'email' to work)"
  type        = string
  default     = "email"
}

variable "sns_topic_name" {
  description = "SNS topic name. Letters, numbers, and hyphens ONLY."
  type        = string
  default     = "slack-events"
}

variable "sns_topic_display_name" {
  description = "SNS topic display name"
  type        = string
  default     = "SlackSNS"
}

resource "aws_cloudformation_stack" "tf_sns_topic" {
  name = var.sns_topic_name
  template_body = templatefile("${path.module}/cf_aws_sns_email_stack.json.tpl",
    {
      sns_topic_name   = var.sns_topic_name
      sns_display_name = var.sns_topic_display_name
      sns_subscription_list = join(",", formatlist("{\"Endpoint\": \"%s\",\"Protocol\": \"%s\"}",
        var.sns_subscription_email_address_list,
        var.sns_subscription_protocol)
      )
    }
  )
  tags = {
    name = var.sns_topic_name
  }
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic."
  value       = aws_cloudformation_stack.tf_sns_topic.outputs["SlackSNSTopic"]
}
