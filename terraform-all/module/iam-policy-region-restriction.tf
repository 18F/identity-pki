# restrict to west-2 and east-1; used by all roles
data "aws_iam_policy_document" "region_restriction" {
  statement {
    sid    = "RegionRestriction"
    effect = "Deny"
    actions = [
      "*",
    ]
    resources = [
      "*",
    ]
    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values = [
        "us-west-2",
        "us-east-1",
      ]
    }
  }
}

resource "aws_iam_policy" "region_restriction" {
  name        = "RegionRestriction"
  path        = "/"
  description = "Limit region usage"
  policy      = data.aws_iam_policy_document.region_restriction.json
}
