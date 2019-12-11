data "aws_iam_policy_document" "master_account_assumerole" {
    statement {
        sid = "AssumeRoleFromMasterAccount"
        actions = [
            "sts:AssumeRole"
        ]
        principals {
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