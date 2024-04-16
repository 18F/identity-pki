resource "aws_iam_role" "events_log_glue_crawler" {
  name               = "${var.env_name}_events_log_glue_crawler"
  assume_role_policy = data.aws_iam_policy_document.glue-assume-role-policy.json
}

resource "aws_iam_role_policy_attachment" "glue_crawler_service_role" {
  role       = aws_iam_role.events_log_glue_crawler.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}
