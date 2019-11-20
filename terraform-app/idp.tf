resource "aws_db_instance" "idp" {
  allocated_storage       = var.rds_storage_idp
  apply_immediately       = true
  backup_retention_period = var.rds_backup_retention_period
  backup_window           = var.rds_backup_window
  db_subnet_group_name    = aws_db_subnet_group.default.id
  engine                  = var.rds_engine
  engine_version          = var.rds_engine_version
  identifier              = "${var.name}-${var.env_name}-idp"
  instance_class          = var.rds_instance_class
  maintenance_window      = var.rds_maintenance_window
  multi_az                = true
  parameter_group_name    = aws_db_parameter_group.force_ssl.name
  password                = var.rds_password # change this by hand after creation
  storage_encrypted       = true
  username                = var.rds_username
  storage_type            = var.rds_storage_type_idp
  iops                    = var.rds_iops_idp

  # we want to push these via Terraform now
  allow_major_version_upgrade = true

  tags = {
    Name = "${var.name}-${var.env_name}"
  }

  # enhanced monitoring
  monitoring_interval = var.rds_enhanced_monitoring_enabled ? 60 : 0
  monitoring_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.rds_monitoring_role_name}"

  vpc_security_group_ids = [aws_security_group.db.id]

  # send logs to cloudwatch
  enabled_cloudwatch_logs_exports = ["postgresql"]

  # If you want to destroy your database, you need to do this in two phases:
  # 1. Uncomment `skip_final_snapshot=true` and
  #    comment `prevent_destroy=true` and `deletion_protection = true` below.
  # 2. Perform a terraform/deploy "apply" with the additional
  #    argument of "-target=aws_db_instance.idp" to mark the database
  #    as not requiring a final snapshot.
  # 3. Perform a terraform/deploy "destroy" as needed.
  #
  #skip_final_snapshot = true
  lifecycle {
    prevent_destroy = true

    # we set the password by hand so it doesn't end up in the state file
    ignore_changes = [password]
  }

  deletion_protection = true
}

output "idp_db_endpoint" {
  value = aws_db_instance.idp.endpoint
}

# Optional read replica of the primary idp database
resource "aws_db_instance" "idp-read-replica" {
  count               = var.enable_rds_idp_read_replica ? 1 : 0
  replicate_source_db = aws_db_instance.idp.id

  identifier = "${var.env_name}-idp-replica"

  tags = {
    Name        = "${var.env_name}-idp-replica"
    description = "Read replica of idp database"
  }

  engine         = var.rds_engine
  instance_class = var.rds_instance_class_replica

  multi_az = false

  allow_major_version_upgrade = true
  parameter_group_name        = aws_db_parameter_group.force_ssl.name

  apply_immediately  = true
  maintenance_window = var.rds_maintenance_window
  storage_encrypted  = true
  username           = var.rds_username
  storage_type       = var.rds_storage_type_idp
  iops               = var.rds_iops_idp_replica

  # enhanced monitoring
  monitoring_interval = var.rds_enhanced_monitoring_enabled ? 60 : 0
  monitoring_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.rds_monitoring_role_name}"

  vpc_security_group_ids = [aws_security_group.db.id]

  # send logs to cloudwatch
  enabled_cloudwatch_logs_exports = ["postgresql"]
}

output "idp_db_endpoint_replica" {
  # This weird element() stuff is so we can refer to these attributes even
  # when the resource has count=0. Reportedly this hack will not
  # be necessary in TF 0.12.
  value = element(concat(aws_db_instance.idp-read-replica.*.endpoint, [""]), 0)
}

resource "aws_db_parameter_group" "force_ssl" {
  name_prefix = "${var.name}-${var.env_name}-idp-${var.rds_engine}${replace(var.rds_engine_version_short, ".", "")}-"

  # Before changing this value, make sure the parameters are correct for the
  # version you are upgrading to.  See
  # http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.html.
  family = "${var.rds_engine}${var.rds_engine_version_short}"

  parameter {
    name         = "rds.force_ssl"
    value        = "1"
    apply_method = "pending-reboot"
  }

  # Log all Data Definition Layer changes (ALTER, CREATE, etc.)
  parameter {
    name  = "log_statement"
    value = "ddl"
  }

  # Log all slow queries that take longer than specified time in ms
  parameter {
    name  = "log_min_duration_statement"
    value = "250" # 250 ms
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Multi-AZ redis cluster, used for session storage
resource "aws_elasticache_replication_group" "idp" {
  replication_group_id          = "${var.env_name}-idp"
  replication_group_description = "Multi AZ redis cluster for the IdP in ${var.env_name}"
  engine                        = "redis"
  engine_version                = var.elasticache_redis_engine_version
  node_type                     = var.elasticache_redis_node_type
  number_cache_clusters         = 2
  parameter_group_name          = var.elasticache_redis_parameter_group_name
  security_group_ids            = [aws_security_group.cache.id]
  subnet_group_name             = aws_elasticache_subnet_group.idp.name
  port                          = 6379

  # note that t2.* instances don't support automatic failover
  automatic_failover_enabled = true
}

resource "aws_iam_instance_profile" "idp" {
  name = "${var.env_name}_idp_instance_profile"
  role = aws_iam_role.idp.name
}

resource "aws_iam_role" "idp" {
  name               = "${var.env_name}_idp_iam_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_from_vpc.json
}

resource "aws_iam_role_policy" "idp-secrets" {
  name   = "${var.env_name}-idp-secrets"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.secrets_role_policy.json
}

resource "aws_iam_role_policy" "idp-secrets-manager" {
  name   = "${var.env_name}-idp-secrets-manager"
  role   = aws_iam_role.idp.id
  policy = <<EOM
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:DescribeSecret",
                "secretsmanager:List*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "secretsmanager:Get*",
            "Resource": [
                "arn:aws:secretsmanager:*:*:secret:global/common/*",
                "arn:aws:secretsmanager:*:*:secret:global/idp/*",
                "arn:aws:secretsmanager:*:*:secret:${var.env_name}/common/*",
                "arn:aws:secretsmanager:*:*:secret:${var.env_name}/idp/*"
            ]
        }
    ]
}
EOM

}

# Allow listing CloudHSM clusters
resource "aws_iam_role_policy" "idp-cloudhsm-client" {
  name   = "${var.env_name}-idp-cloudhsm-client"
  role   = aws_iam_role.idp.id
  policy = <<EOM
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudhsm:DescribeClusters",
                "cloudhsm:ListTags",
                "cloudhsm:ListTagsForResource"
            ],
            "Resource": "*"
        }
    ]
}
EOM

}

resource "aws_iam_role_policy" "idp-certificates" {
  name   = "${var.env_name}-idp-certificates"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.certificates_role_policy.json
}

resource "aws_iam_role_policy" "idp-describe_instances" {
  name   = "${var.env_name}-idp-describe_instances"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.describe_instances_role_policy.json
}

resource "aws_iam_role_policy" "idp-application-secrets" {
  name   = "${var.env_name}-idp-application-secrets"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.application_secrets_role_policy.json
}

resource "aws_iam_role_policy" "idp-ses-email" {
  name   = "${var.env_name}-idp-ses-email"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.ses_email_role_policy.json
}

resource "aws_iam_role_policy" "idp-cloudwatch-logs" {
  name   = "${var.env_name}-idp-cloudwatch-logs"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.cloudwatch-logs.json
}

resource "aws_iam_role_policy" "idp-upload-s3-reports" {
  name   = "${var.env_name}-idp-s3-reports"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.put_reports_to_s3.json
}

# This policy allows writing to the S3 reports bucket
data "aws_iam_policy_document" "put_reports_to_s3" {
  statement {
    sid    = "PutObjectsToReportsS3Bucket"
    effect = "Allow"
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "arn:aws:s3:::login-gov.reports.${data.aws_caller_identity.current.account_id}-${var.region}/${var.env_name}/*",
    ]
  }

  # allow listing objects so we can see what we've uploaded
  statement {
    sid    = "ListBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::login-gov.reports.${data.aws_caller_identity.current.account_id}-${var.region}",
    ]
  }
}

# Allow assuming cross-account role for Pinpoint APIs. This is in a separate
# account for accounting purposes since it's on a separate contract.
resource "aws_iam_role_policy" "idp-pinpoint-assumerole" {
  name   = "${var.env_name}-idp-pinpoint-assumerole"
  role   = aws_iam_role.idp.id
  policy = <<EOM
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": [
        "arn:aws:iam::${var.identity_sms_aws_account_id}:role/${var.identity_sms_iam_role_name_idp}"
      ]
    }
  ]
}
EOM

}

# Allow sending SMS/Voice messages with Pinpoint
# (Deprecated: TODO remove)
resource "aws_iam_role_policy" "idp-pinpoint-send" {
  name   = "${var.env_name}-idp-pinpoint-send"
  role   = aws_iam_role.idp.id
  policy = <<EOM
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "mobiletargeting:PhoneNumberValidate",
                "mobiletargeting:SendMessages",
                "mobiletargeting:SendUsersMessages",
                "sms-voice:SendVoiceMessage"
            ],
            "Resource": "*"
        }
    ]
}
EOM

}

module "idp_user_data" {
  source = "../terraform-modules/bootstrap/"

  role   = "idp"
  env    = var.env_name
  domain = var.root_domain

  chef_download_url    = var.chef_download_url
  chef_download_sha256 = var.chef_download_sha256

  # identity-devops-private variables
  private_s3_ssh_key_url = local.bootstrap_private_s3_ssh_key_url
  private_git_clone_url  = var.bootstrap_private_git_clone_url
  private_git_ref        = var.bootstrap_private_git_ref

  # identity-devops variables
  main_s3_ssh_key_url  = local.bootstrap_main_s3_ssh_key_url
  main_git_clone_url   = var.bootstrap_main_git_clone_url
  main_git_ref_map     = var.bootstrap_main_git_ref_map
  main_git_ref_default = local.bootstrap_main_git_ref_default

  # proxy variables
  proxy_server        = var.proxy_server
  proxy_port          = var.proxy_port
  no_proxy_hosts      = var.no_proxy_hosts
  proxy_enabled_roles = var.proxy_enabled_roles
}

module "idp_launch_template" {
  source = "github.com/18F/identity-terraform//launch_template?ref=1db3ba569822d7803f2f6701fab5bc3242e2bb36"

  role           = "idp"
  env            = var.env_name
  root_domain    = var.root_domain
  ami_id_map     = var.ami_id_map
  default_ami_id = local.account_default_ami_id

  instance_type             = var.instance_type_idp
  iam_instance_profile_name = aws_iam_instance_profile.idp.name
  security_group_ids        = [aws_security_group.idp.id, aws_security_group.base.id]

  user_data = module.idp_user_data.rendered_cloudinit_config

  template_tags = {
    main_git_ref = module.idp_user_data.main_git_ref
  }
}

resource "aws_autoscaling_group" "idp" {
  name = "${var.env_name}-idp"

  launch_template {
    id      = module.idp_launch_template.template_id
    version = "$Latest"
  }

  min_size         = var.asg_idp_min
  max_size         = var.asg_idp_max
  desired_capacity = var.asg_idp_desired

  wait_for_capacity_timeout = 0

  # Don't create an IDP ASG if we don't have an ALB.
  # We can't refer to aws_alb_target_group.idp unless it exists.
  count = var.alb_enabled

  target_group_arns = [
    aws_alb_target_group.idp[0].arn,
    aws_alb_target_group.idp-ssl[0].arn,
  ]

  vpc_zone_identifier = [
    aws_subnet.idp1.id,
    aws_subnet.idp2.id,
  ]

  # possible choices: EC2, ELB
  health_check_type = "ELB"

  # The grace period starts after lifecycle hooks are done and the instance
  # is InService. Having a grace period is dangerous because the ASG
  # considers instances in the grace period to be healthy.
  health_check_grace_period = 0

  termination_policies = ["OldestInstance"]

  # Because bootstrapping takes so long, we terminate manually in prod
  # More context on ASG deploys and safety:
  # https://github.com/18F/identity-devops-private/issues/337
  protect_from_scale_in = var.asg_prevent_auto_terminate

  enabled_metrics = var.asg_enabled_metrics

  # tags on the instance will come from the launch template
  tag {
    key                 = "prefix"
    value               = "idp"
    propagate_at_launch = false
  }
  tag {
    key                 = "domain"
    value               = "${var.env_name}.${var.root_domain}"
    propagate_at_launch = false
  }
}

module "idp_lifecycle_hooks" {
  source   = "github.com/18F/identity-terraform//asg_lifecycle_notifications?ref=1db3ba569822d7803f2f6701fab5bc3242e2bb36"
  asg_name = aws_autoscaling_group.idp[0].name
}

module "idp_recycle" {
  source = "github.com/18F/identity-terraform//asg_recycle?ref=1db3ba569822d7803f2f6701fab5bc3242e2bb36"

  # switch to count when that's a thing that we can do
  # https://github.com/hashicorp/terraform/issues/953
  enabled = var.asg_auto_recycle_enabled

  use_daily_business_hours_schedule = var.asg_auto_recycle_use_business_schedule

  asg_name                = aws_autoscaling_group.idp[0].name
  normal_desired_capacity = aws_autoscaling_group.idp[0].desired_capacity
}

resource "aws_autoscaling_policy" "idp-cpu" {
  count = var.idp_cpu_autoscaling_enabled

  autoscaling_group_name = aws_autoscaling_group.idp[0].name
  name                   = "cpu-scaling"

  # currently it takes about 15 minutes for instances to bootstrap
  estimated_instance_warmup = 900

  policy_type = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = var.idp_cpu_autoscaling_target

    disable_scale_in = var.idp_cpu_autoscaling_disable_scale_in
  }
}

resource "aws_route53_record" "idp-postgres" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "idp-postgres"

  type    = "CNAME"
  ttl     = "300"
  records = [replace(aws_db_instance.idp.endpoint, ":5432", "")]
}

resource "aws_route53_record" "redis" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "redis"

  type    = "CNAME"
  ttl     = "300"
  records = [aws_elasticache_replication_group.idp.primary_endpoint_address]
}

