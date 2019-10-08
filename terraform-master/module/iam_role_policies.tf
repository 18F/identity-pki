resource "aws_iam_policy" "master_full_administrator" {
    name = "MasterAssumeFullAdministator"
    path = "/"
    description = "Policy to assign that permits user to assume full administrator role in master"
    policy = "${data.aws_iam_policy_document.master_full_administrator.json}"
}

data "aws_iam_policy_document" "master_full_administrator" {
    statement {
        sid = "MasterAssumeFullAdministratorWithMFA"
        effect = "Allow"
        actions = [
            "sts:AssumeRole"
        ]
        resources = [
            "${aws_iam_role.master_full_administrator.arn}"
        ]
    }
}

