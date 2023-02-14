module "usps_updates" {
  count  = var.enable_usps_status_updates ? 1 : 0
  source = "../modules/usps_status_update_via_email"

  env_name    = var.env_name
  root_domain = var.root_domain
  route53_id  = var.route53_id
}

data "aws_iam_policy_document" "usps_queue_policy" {
  count = var.enable_usps_status_updates ? 1 : 0
  statement {
    sid    = "ReadAttributes"
    effect = "Allow"
    actions = [
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
    ]

    resources = [
      module.usps_updates[0].sqs_arn
    ]
  }

  statement {
    sid    = "Messages"
    effect = "Allow"
    actions = [
      "sqs:DeleteMessage",
      "sqs:ReceiveMessage",
    ]

    resources = [
      module.usps_updates[0].sqs_arn
    ]
  }
}
