resource "aws_db_instance" "default" {
  allocated_storage    = var.rds_storage_app
  apply_immediately    = true
  count                = var.apps_enabled
  db_subnet_group_name = aws_db_subnet_group.default.id
  depends_on = [
    aws_security_group.db,
    aws_subnet.db1,
    aws_subnet.db2,
  ]
  engine         = var.rds_engine
  engine_version = var.rds_engine_version

  # TODO: rename to "${var.env_name}-sampleapps" (forces new resource)
  identifier     = "${var.name}-${var.env_name}"
  instance_class = var.rds_instance_class
  password       = var.rds_password
  username       = var.rds_username

  # we want to push these via Terraform now
  allow_major_version_upgrade = true

  tags = {
    Name = "${var.name}-${var.env_name}-app"
  }

  # enhanced monitoring
  monitoring_interval = var.rds_enhanced_monitoring_enabled == 1 ? 60 : 0
  monitoring_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.rds_monitoring_role_name}"

  vpc_security_group_ids = [aws_security_group.db.id]

  # If you want to destroy your database, you need to do this in two phases:
  # 1. Uncomment `skip_final_snapshot=true` and
  #    comment `prevent_destroy=true`
  # 2. Perform a terraform/deploy "apply" with the additional
  #    argument of "-target=aws_db_instance.default" to mark the database
  #    as not requiring a final snapshot.
  # 3. Perform a terraform/deploy "destroy" as needed.
  #
  #skip_final_snapshot = true
  lifecycle {
    prevent_destroy = true

    # we set the password by hand so it doesn't end up in the state file
    ignore_changes = [password]
  }
}

output "app_db_endpoint" {
  value = element(concat(aws_db_instance.default.*.endpoint, [""]), 0)
}

resource "aws_db_subnet_group" "default" {
  description = "${var.env_name} env subnet group for login.gov"
  name        = "${var.name}-db-${var.env_name}"
  subnet_ids  = [aws_subnet.db1.id, aws_subnet.db2.id]

  tags = {
    Name = "${var.name}-${var.env_name}"
  }
}

resource "aws_route53_record" "app_internal" {
  count   = var.apps_enabled
  name    = "app.login.gov.internal"
  zone_id = aws_route53_zone.internal.zone_id
  records = [aws_alb.app[0].dns_name]
  ttl     = "300"
  type    = "CNAME"
}

resource "aws_route53_record" "app_external" {
  count   = var.apps_enabled
  name    = "app.${var.env_name}.${var.root_domain}"
  zone_id = var.route53_id
  records = [aws_alb.app[0].dns_name]
  ttl     = "300"
  type    = "CNAME"
}

resource "aws_route53_record" "c_dash" {
  count   = var.apps_enabled == 1 ? 1 : 0
  name    = "dashboard.${var.env_name}.${var.root_domain}"
  records = ["app.${var.env_name}.${var.root_domain}"]
  ttl     = "300"
  type    = "CNAME"
  zone_id = var.route53_id
}

resource "aws_route53_record" "c_sp" {
  count   = var.apps_enabled
  name    = "sp.${var.env_name}.${var.root_domain}"
  records = ["app.${var.env_name}.${var.root_domain}"]
  ttl     = "300"
  type    = "CNAME"
  zone_id = var.route53_id
}

resource "aws_route53_record" "c_sp_oidc_sinatra" {
  count   = var.apps_enabled
  name    = "sp-oidc-sinatra.${var.env_name}.${var.root_domain}"
  records = ["app.${var.env_name}.${var.root_domain}"]
  ttl     = "300"
  type    = "CNAME"
  zone_id = var.route53_id
}

resource "aws_route53_record" "c_sp_rails" {
  count   = var.apps_enabled
  name    = "sp-rails.${var.env_name}.${var.root_domain}"
  records = ["app.${var.env_name}.${var.root_domain}"]
  ttl     = "300"
  type    = "CNAME"
  zone_id = var.route53_id
}

resource "aws_route53_record" "c_sp_sinatra" {
  count   = var.apps_enabled
  name    = "sp-sinatra.${var.env_name}.${var.root_domain}"
  records = ["app.${var.env_name}.${var.root_domain}"]
  ttl     = "300"
  type    = "CNAME"
  zone_id = var.route53_id
}

resource "aws_route53_record" "postgres" {
  count   = var.apps_enabled
  name    = "postgres"
  records = [replace(aws_db_instance.default[0].endpoint, ":5432", "")]
  ttl     = "300"
  type    = "CNAME"
  zone_id = aws_route53_zone.internal.zone_id
}

# S3 bucket for partners to upload and serve logos
resource "aws_s3_bucket" "partner_logos_bucket" {
  # Conditionally create this bucket only if enable_partner_logos_bucket is set to true
  count = var.apps_enabled

  bucket = "login-gov-partner-logos-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"
  acl    = "public-read"

  logging {
    target_bucket = "login-gov.s3-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
    target_prefix = "${var.env_name}/s3-access-logs/login-gov-partner-logos/"
  }

  tags = {
    Name = "login-gov-partner-logos-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"
  }

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  policy = data.aws_iam_policy_document.partner_logos_bucket_policy.json

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled = true
  }
}

data "aws_iam_policy_document" "partner_logos_bucket_policy" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectVersionAcl",
      "s3:AbortMultipartUpload",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:GetObjectVersionAcl",
      "s3:ListBucket",
      "s3:DeleteObject", 
    ]
    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.app.arn,
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AppDev",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/FullAdministrator",
      ]
    }

    resources = [
      "arn:aws:s3:::login-gov-partner-logos-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}",
      "arn:aws:s3:::login-gov-partner-logos-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}/*",
    ]
  }
}

resource "aws_iam_role_policy" "app-s3-logos-access" {
  name   = "${var.env_name}-app-s3-logos-access"
  role   = aws_iam_role.app.id
  policy = <<EOM
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:AbortMultipartUpload",
                "s3:GetObject",
                "s3:ListObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::login-gov-partner-logos-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}",
                "arn:aws:s3:::login-gov-partner-logos-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}/*"
            ]
        }
    ]
}
EOM
}
