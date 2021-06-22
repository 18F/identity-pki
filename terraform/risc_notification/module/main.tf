# changing the eventbus_name will require updating
# the idp role policy in app/idp.tf
locals {
  eventbus_name = "${var.env_name}-risc-notifications"
}

resource "aws_cloudwatch_event_bus" "risc_notifications" {
  name = local.eventbus_name
}

resource "aws_cloudformation_stack" "risc_notifications" {
  depends_on = [
    aws_cloudwatch_event_bus.risc_notifications
  ]
  for_each      = var.risc_notifications
  name          = "${var.env_name}-risc-${each.value["partner_name"]}"
  template_body = file("${path.module}/risc_notification.template")
  parameters = {
    EventBusName            = local.eventbus_name
    EventBusArn             = aws_cloudwatch_event_bus.risc_notifications.arn
    NotificationName        = "${var.env_name}-${each.value["partner_name"]}"
    NotificationEndpointUrl = each.value["notification_url"]
    NotificationRateLimit   = each.value["notification_rate_limit"]
    NotificationSource      = each.value["notification_source"]
    NotificationState       = each.value["notification_state"]
    AuthType                = each.value["authentication_type"]
    BasicAuthUserName       = each.value["basic_auth_user_name"]
    ApiKeyName              = each.value["api_key_name"]
  }
  capabilities = [
    "CAPABILITY_IAM"
  ]
}

resource "aws_iam_role" "risc_notification_destination" {
  name               = "${var.env_name}-risc-notification-destination"
  assume_role_policy = data.aws_iam_policy_document.risc_notification_destination.json
}

data "aws_iam_policy_document" "risc_notification_destination_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "risc_notification_destination" {
  statement {
    effect = "Allow"
    actions = [
      "events:InvokeApiDestination"
    ]
    resources = [
      "arn:aws:events:${var.region}:${data.aws_caller_identity.current.account_id}:api-destination/${var.env_name}-risc-*"
    ]
  }
}

resource "aws_iam_role_policy" "risc_notification_destination" {
  name   = "${var.env_name}-app-risc-notification-apidestination"
  role   = aws_iam_role.risc_notification_destination.id
  policy = data.aws_iam_policy_document.risc_notification_destination.json
}
