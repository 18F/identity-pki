# Hack to allow email-based SNS subscription creation in Terraform using CloudFormation:
# https://medium.com/@raghuram.arumalla153/aws-sns-topic-subscription-with-email-protocol-using-terraform-ed05f4f19b73

# -- Variables --

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
  description = "SNS topic name"
  type        = string
  default     = "identity-events"
}

variable "sns_topic_display_name" {
  description = "SNS topic display name"
  type        = string
  default     = "identity-events"
}

data "template_file" "aws_cf_sns_stack" {
  template = file("${path.module}/cf_aws_sns_email_stack.json.tpl")
  vars = {
    sns_topic_name        = var.sns_topic_name
    sns_display_name      = var.sns_topic_display_name
    sns_subscription_list = join(",", formatlist("{\"Endpoint\": \"%s\",\"Protocol\": \"%s\"}",
    var.sns_subscription_email_address_list,
    var.sns_subscription_protocol))
  }
}

resource "aws_cloudformation_stack" "tf_sns_topic" {
  name = "identity-events-SNS"
  template_body = data.template_file.aws_cf_sns_stack.rendered
  tags = {
    name = "identity-events-SNS"
  }
}
