resource "aws_iam_role" "secrets_iam_role" {
  name = "${var.env_name}_secrets_iam_role"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_from_vpc.json}"
}

resource "aws_iam_instance_profile" "secrets_instance_profile" {
  name = "${var.env_name}_secrets_instance_profile"
  roles = ["${aws_iam_role.secrets_iam_role.name}"]
}

data "aws_iam_policy_document" "secretsbucketpolicy" {
  statement {
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::login-gov-${var.env_name}-secrets"
    ]
  }
  statement {
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::login-gov-${var.env_name}-secrets/*"
    ]
  }
}

resource "aws_iam_role_policy" "secrets_iam_role_policy" {
  name = "${var.env_name}_secrets_iam_role_policy"
  role = "${aws_iam_role.secrets_iam_role.id}"
  policy = "${data.aws_iam_policy_document.secretsbucketpolicy.json}"
}

resource "aws_s3_bucket" "secretsBucket" {
  bucket = "login-gov-${var.env_name}-secrets"
  acl = "private"
   tags {
       Name = "Secrets Bucket"
       Environment = "${var.env_name}"
   }
}
