resource "aws_iam_policy" "soc_administrator" {
    name = "SOCAdministrator"
    path = "/"
    description = "Policy for SOC administrators"
    policy = data.aws_iam_policy_document.soc_administrator.json
}

data "aws_iam_policy_document" "soc_administrator" {
    statement {
        sid = "SOCAdministrator"
        effect = "Allow"
        actions = [
            "cloudtrail:*",
            "cloudwatch:*",
            "logs:*",
            "config:*",
            "guardduty:*",
            "iam:Get*",
            "iam:List*",
            "iam:Generate*",
            "inspector:*",
            "macie:*",
            "organizations:List*",
            "organizations:Describe*",
            "s3:HeadBucket",
            "s3:List*",
            "s3:Get*",
            "securityhub:*",
            "shield:*",
            "ssm:*",
            "trustedadvisor:*",
            "waf:*"
        ]
        resources = [
            "*"
        ]
    }
}
