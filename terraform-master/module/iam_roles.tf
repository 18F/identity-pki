resource "aws_iam_role" "master_full_administrator" {
  name                 = "FullAdministrator"
  assume_role_policy   = data.aws_iam_policy_document.master_full_administrator_role.json
  path                 = "/"
  max_session_duration = 3600 #seconds
}

resource "aws_iam_role_policy_attachment" "master_full_administrator" {
  role       = aws_iam_role.master_full_administrator.name
  policy_arn = aws_iam_policy.full_administrator.arn
}

data "aws_iam_policy_document" "master_full_administrator_role" {
  statement {
    sid = "MasterFullAdministrator"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
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

resource "aws_iam_role" "master_socadministrator" {
  name                 = "SOCAdministrator"
  assume_role_policy   = data.aws_iam_policy_document.master_socadministrator_role.json
  path                 = "/"
  max_session_duration = 3600 #seconds
}

resource "aws_iam_role_policy_attachment" "master_socadministrator" {
  role       = aws_iam_role.master_socadministrator.name
  policy_arn = aws_iam_policy.socadministrator.arn
}

data "aws_iam_policy_document" "master_socadministrator_role" {
  statement {
    sid = "MasterSOCAdministrator"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values = [
        "true"
      ]
    }
  }
}

resource "aws_iam_role" "master_billing_readonly" {
  name                 = "BillingReadOnly"
  assume_role_policy   = data.aws_iam_policy_document.master_billing_readonly_role.json
  path                 = "/"
  max_session_duration = 3600 #seconds
}

resource "aws_iam_role_policy_attachment" "master_billing_readonly" {
  role       = aws_iam_role.master_billing_readonly.name
  policy_arn = aws_iam_policy.billing_readonly.arn
}

data "aws_iam_policy_document" "master_billing_readonly_role" {
  statement {
    sid = "MasterBillingReadOnly"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
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

resource "aws_iam_role" "master_auditor" {
  name                 = "Auditor"
  assume_role_policy   = data.aws_iam_policy_document.master_auditor_role.json
  path                 = "/"
  max_session_duration = 3600 #seconds
}

resource "aws_iam_role_policy_attachment" "master_auditor" {
  role       = aws_iam_role.master_auditor.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

data "aws_iam_policy_document" "master_auditor_role" {
  statement {
    sid = "MasterAuditor"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
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
