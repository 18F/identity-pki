# This role is created by the RDS wizard when you enable enhanced monitoring on
# an RDS DB instance. It's just a role to wrap the AWS managed policy
# "AmazonRDSEnhancedMonitoringRole".
resource "aws_iam_role" "rds-monitoring-role" {
  name = "rds-monitoring-role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "monitoring.rds.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "rds-enhanced-monitoring" {
  role       = aws_iam_role.rds-monitoring-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_iam_user" "circleci" {
  name = "bot=circleci"
  path = "/system/"
}

resource "aws_iam_role" "full_administrator" {
  name                 = "FullAdministrator"
  assume_role_policy   = data.aws_iam_policy_document.allow_master_account_assumerole.json
  path                 = "/"
  max_session_duration = 43200 #seconds
}

resource "aws_iam_role_policy_attachment" "full_administrator" {
  role       = aws_iam_role.full_administrator.name
  policy_arn = aws_iam_policy.full_administrator.arn
}

resource "aws_iam_role_policy_attachment" "region_restriction" {
  role       = aws_iam_role.full_administrator.name
  policy_arn = aws_iam_policy.region_restriction.arn
}

data "aws_iam_policy_document" "allow_master_account_assumerole" {
  statement {
    sid = "AssumeRoleFromMasterAccount"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.master_account_id}:root",
      ]
    }
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values = [
        "true",
      ]
    }
  }
}

resource "aws_iam_role" "power" {
  name                 = "PowerUser"
  assume_role_policy   = data.aws_iam_policy_document.allow_master_account_assumerole.json
  path                 = "/"
  max_session_duration = 43200 #seconds
}

resource "aws_iam_role_policy_attachment" "power1" {
  role       = aws_iam_role.power.name
  policy_arn = aws_iam_policy.power1.arn
}

resource "aws_iam_role_policy_attachment" "power2" {
  role       = aws_iam_role.power.name
  policy_arn = aws_iam_policy.power2.arn
}

resource "aws_iam_role_policy_attachment" "power_rds_delete_prevent" {
  role       = aws_iam_role.power.name
  policy_arn = aws_iam_policy.rds_delete_prevent.arn
}

resource "aws_iam_role_policy_attachment" "power_region_restriction" {
  role       = aws_iam_role.power.name
  policy_arn = aws_iam_policy.region_restriction.arn
}

resource "aws_iam_role" "readonly" {
  name                 = "ReadOnly"
  assume_role_policy   = data.aws_iam_policy_document.allow_master_account_assumerole.json
  path                 = "/"
  max_session_duration = 43200 #seconds
}

resource "aws_iam_role_policy_attachment" "readonly1" {
  role       = aws_iam_role.readonly.name
  policy_arn = aws_iam_policy.readonly1.arn
}

resource "aws_iam_role_policy_attachment" "readonly2" {
  role       = aws_iam_role.readonly.name
  policy_arn = aws_iam_policy.readonly2.arn
}

resource "aws_iam_role_policy_attachment" "readonly_region_restriction" {
  role       = aws_iam_role.readonly.name
  policy_arn = aws_iam_policy.region_restriction.arn
}

resource "aws_iam_role" "appdev" {
  name                 = "Appdev"
  assume_role_policy   = data.aws_iam_policy_document.allow_master_account_assumerole.json
  path                 = "/"
  max_session_duration = 43200 #seconds
}

resource "aws_iam_role_policy_attachment" "appdev1" {
  role       = aws_iam_role.appdev.name
  policy_arn = aws_iam_policy.appdev1.arn
}

resource "aws_iam_role" "reports_ro" {
  name                 = "ReportsReadOnly"
  assume_role_policy   = data.aws_iam_policy_document.allow_master_account_assumerole.json
  path                 = "/"
  max_session_duration = 43200 #seconds
}

resource "aws_iam_role_policy_attachment" "reports_ro" {
  role       = aws_iam_role.reports_ro.name
  policy_arn = aws_iam_policy.reports_ro.arn
}
