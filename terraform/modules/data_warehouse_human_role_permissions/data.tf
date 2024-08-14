data "aws_caller_identity" "current" {}

data "aws_iam_role" "targets" {
  for_each = toset(var.roles)
  name     = each.key
}

data "aws_iam_policy" "redshift_read_only" {
  arn = "arn:aws:iam::aws:policy/AmazonRedshiftReadOnlyAccess"
}

data "aws_iam_policy" "query_editor_no_sharing" {
  arn = "arn:aws:iam::aws:policy/AmazonRedshiftQueryEditorV2NoSharing"
}
