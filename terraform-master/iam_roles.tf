resource "aws_iam_role" "assume_full_administrator" {
    name = "AssumeFullAdministrator"
    assume_role_policy = "${data.aws_iam_policy_document.full_administrator_role.json}"
    path = "/"
    max_session_duration = 3600 #seconds
}

resource "aws_iam_role_policy_attachment" "assume_full_administrator" {
    role = "${aws_iam_role.assume_full_administrator.name}"
    policy_arn = "${aws_iam_policy.full_administrator.arn}"

}

data "aws_iam_policy_document" "full_administrator_role" {
    statement {
        sid = "AssumeFullAdministrator"
        actions = [
            "sts:AssumeRole"
        ]
        principals = {
            type = "AWS"
            identifiers = [
                "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
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