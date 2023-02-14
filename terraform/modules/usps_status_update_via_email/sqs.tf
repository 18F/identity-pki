resource "aws_sqs_queue" "usps" {
  name = "usps-${var.env_name}-queue"
}

output "sqs_arn" {
  value = aws_sqs_queue.usps.arn
}

resource "aws_sqs_queue_policy" "usps_policy" {
  queue_url = aws_sqs_queue.usps.id

  policy = data.aws_iam_policy_document.usps_queue_policy.json
}

data "aws_iam_policy_document" "usps_queue_policy" {

  statement {
    actions = [
      "sqs:SendMessage"
    ]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    resources = [
      aws_sqs_queue.usps.arn
    ]
  }

}
