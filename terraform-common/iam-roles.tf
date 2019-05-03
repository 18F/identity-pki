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
    role = "${aws_iam_role.rds-monitoring-role.name}"
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_iam_user" "circleci" {
  name = "bot=circleci"
  path = "/system/"
}

resource "aws_iam_role" "full_administrator" {
    name = "FullAdministrator"
    assume_role_policy = "${data.aws_iam_policy_document.assume_full_administrator_role.json}"
    path = "/"
    max_session_duration = 3600 #seconds
}

resource "aws_iam_role_policy_attachment" "full_administrator" {
    role = "${aws_iam_role.full_administrator.name}"
    policy_arn = "${aws_iam_policy.full_administrator.arn}"
}

data "aws_iam_policy_document" "assume_full_administrator_role" {
    statement {
        sid = "AssumeFullAdministrator"
        actions = [
            "sts:AssumeRole"
        ]
        principals = {
            type = "AWS"
            identifiers = [
                "arn:aws:iam::${var.master_account_id}:root"
            ]
        }
        condition {
            test = "Bool"
            variable = "aws:MultiFactorAuthPresent"
            values = [
                "true"
            ]
        }
    }
}

resource "aws_iam_policy" "full_administrator"
{
    name = "FullAdministratorWithMFA"
    path = "/"
    description = "Policy for full administrator with MFA"
    policy = "${data.aws_iam_policy_document.full_administrator.json}"
}

data "aws_iam_policy_document" "full_administrator" {
    statement {
        sid = "FullAdministratorWithMFA"
        effect = "Allow"
        actions = [
            "*"
        ]
        resources = [
            "*"
        ]
        condition = {
            test = "Bool"
            variable = "aws:MultiFactorAuthPresent"
            values = [
                "true"
            ]
        }
    }
}
