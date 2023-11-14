data "aws_s3_object" "ca_certificate_file" {
  bucket = var.cert_bucket
  key    = "ca_certificate_file"
}

data "aws_iam_policy_document" "dms_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["dms.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "dms_kms" {
  statement {
    sid    = "AllowDecryptFromKMS"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]
    resources = [
      "${var.rds_kms_key_arn}"
    ]
  }
}

resource "aws_iam_role" "dms" {
  name               = "${var.env_name}-dms"
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
}

resource "aws_iam_role_policy" "dms_kms" {
  name   = "${var.env_name}-dms-kms"
  role   = aws_iam_role.dms.id
  policy = data.aws_iam_policy_document.dms_kms.json
}

resource "aws_iam_role_policy_attachment" "dms_redshift_s3" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSRedshiftS3Role"
  role       = aws_iam_role.dms.name
}

resource "aws_iam_role_policy_attachment" "dms_cloudwatch_logs" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
  role       = aws_iam_role.dms.name
}

resource "aws_iam_role_policy_attachment" "dms_vpc_management" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
  role       = aws_iam_role.dms.name
}

resource "aws_cloudwatch_log_group" "dms" {
  name              = "${var.env_name}-dms-tasks"
  retention_in_days = 365
}

resource "aws_dms_certificate" "dms" {
  certificate_id  = "${var.env_name}-dms-certificate"
  certificate_pem = data.aws_s3_object.ca_certificate_file.body

  lifecycle {
    ignore_changes = [
      certificate_pem
    ]
  }
}

resource "aws_dms_endpoint" "aurora_source" {
  certificate_arn             = aws_dms_certificate.dms.certificate_arn
  database_name               = "idp"
  endpoint_id                 = "${var.env_name}-dms-source"
  endpoint_type               = "source"
  engine_name                 = "aurora-postgresql"
  extra_connection_attributes = ""
  kms_key_arn                 = var.rds_kms_key_arn
  password                    = var.rds_password
  port                        = 5432
  server_name                 = var.source_db_address
  ssl_mode                    = "require"
  username                    = var.rds_username
}

resource "aws_dms_endpoint" "aurora_target" {
  certificate_arn             = aws_dms_certificate.dms.certificate_arn
  database_name               = "idp"
  endpoint_id                 = "${var.env_name}-dms-target"
  endpoint_type               = "target"
  engine_name                 = "aurora-postgresql"
  extra_connection_attributes = ""
  kms_key_arn                 = var.rds_kms_key_arn
  password                    = var.rds_password
  port                        = 5432
  server_name                 = var.target_db_address
  ssl_mode                    = "require"
  username                    = var.rds_username
}

resource "aws_dms_replication_subnet_group" "dms" {
  replication_subnet_group_description = "DMS replication subnet group for ${var.env_name}"
  replication_subnet_group_id          = "${var.env_name}-dms"

  subnet_ids = var.subnet_ids
}

resource "aws_dms_replication_instance" "dms" {
  allocated_storage            = var.source_db_allocated_storage
  apply_immediately            = true
  auto_minor_version_upgrade   = true
  availability_zone            = var.source_db_availability_zone
  engine_version               = var.dms_engine_version
  kms_key_arn                  = var.rds_kms_key_arn
  multi_az                     = false
  preferred_maintenance_window = "sun:10:30-sun:14:30"
  publicly_accessible          = false
  replication_instance_class   = replace(var.source_db_instance_class, "db", "dms")
  replication_instance_id      = "${var.env_name}-dms-replication-instance"
  replication_subnet_group_id  = aws_dms_replication_subnet_group.dms.id

  vpc_security_group_ids = var.vpc_security_group_ids

}
