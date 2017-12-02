resource "aws_db_instance" "idp" {
  allocated_storage = "${var.rds_storage_idp}"
  apply_immediately = true
  backup_retention_period = "${var.rds_backup_retention_period}"
  backup_window = "${var.rds_backup_window}"
  db_subnet_group_name = "${aws_db_subnet_group.default.id}"
  # TODO: these deps prevent cleanly destroying an RDS instance, and they should probably be removed
  depends_on = ["aws_security_group.db", "aws_subnet.db1", "aws_subnet.db2", "aws_db_parameter_group.force_ssl"]
  engine = "${var.rds_engine}"
  engine_version = "${var.rds_engine_version}"
  identifier = "${var.name}-${var.env_name}-idp"
  instance_class = "${var.rds_instance_class}"
  maintenance_window = "${var.rds_maintenance_window}"
  multi_az = true
  parameter_group_name = "${aws_db_parameter_group.force_ssl.name}"
  password = "${var.rds_password}"
  storage_encrypted = true
  username = "${var.rds_username}"

  # change this to true to allow upgrading engine versions
  allow_major_version_upgrade = false

  tags {
    client = "${var.client}"
    Name = "${var.name}-${var.env_name}"
  }

  vpc_security_group_ids = ["${aws_security_group.db.id}"]

  # If you want to destroy your database, you need to do this in two phases:
  # 1. Uncomment `skip_final_snapshot=true` and
  #    comment `prevent_destroy=true` below.
  # 2. Perform a terraform/deploy "apply" with the additional
  #    argument of "-target=aws_db_instance.idp" to mark the database
  #    as not requiring a final snapshot.
  # 3. Perform a terraform/deploy "destroy" as needed.
  #
  #skip_final_snapshot = true
  lifecycle {
    prevent_destroy = true

    # we set the password by hand so it doesn't end up in the state file
    ignore_changes = ["password"]
  }
}

output "idp_db_endpoint" {
  value = "${aws_db_instance.idp.endpoint}"
}

resource "aws_db_parameter_group" "force_ssl" {
  name = "${var.name}-idp-force-ssl-${var.env_name}-${var.rds_engine}${replace(var.rds_engine_version_short, ".", "")}"
  # Before changing this value, make sure the parameters are correct for the
  # version you are upgrading to.  See
  # http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.html.
  family = "${var.rds_engine}${var.rds_engine_version_short}"

  parameter {
    name = "rds.force_ssl"
    value = "1"
    apply_method = "pending-reboot"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elasticache_cluster" "idp" {
  cluster_id = "login-idp-${var.env_name}"
  engine = "redis"
  node_type = "cache.t2.micro"
  num_cache_nodes = 1
  parameter_group_name = "default.redis3.2"
  port = 6379
  security_group_ids = ["${aws_security_group.cache.id}"]
  subnet_group_name = "${aws_elasticache_subnet_group.idp.name}"
}

resource "aws_iam_instance_profile" "idp" {
  name = "${var.env_name}_idp_instance_profile"
  roles = ["${aws_iam_role.idp.name}"]
}

resource "aws_iam_role" "idp" {
  name = "${var.env_name}_idp_iam_role"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_from_vpc.json}"
}

resource "aws_iam_role_policy" "idp-secrets" {
  name = "${var.env_name}-idp-secrets"
  role = "${aws_iam_role.idp.id}"
  policy = "${data.aws_iam_policy_document.secrets_role_policy.json}"
}

resource "aws_iam_role_policy" "idp-certificates" {
  name = "${var.env_name}-idp-certificates"
  role = "${aws_iam_role.idp.id}"
  policy = "${data.aws_iam_policy_document.certificates_role_policy.json}"
}

resource "aws_iam_role_policy" "idp-describe_instances" {
  name = "${var.env_name}-idp-describe_instances"
  role = "${aws_iam_role.idp.id}"
  policy = "${data.aws_iam_policy_document.describe_instances_role_policy.json}"
}

resource "aws_iam_role_policy" "idp-application-secrets" {
    name = "${var.env_name}-idp-application-secrets"
    role = "${aws_iam_role.idp.id}"
    policy = "${data.aws_iam_policy_document.application_secrets_role_policy.json}"
}

resource "aws_iam_role_policy" "idp-ses-email" {
  name = "${var.env_name}-idp-ses-email"
  role = "${aws_iam_role.idp.id}"
  policy = "${data.aws_iam_policy_document.ses_email_role_policy.json}"
}

resource "aws_iam_role_policy" "idp-cloudwatch-logs" {
  name = "${var.env_name}-idp-cloudwatch-logs"
  role = "${aws_iam_role.idp.id}"
  policy = "${data.aws_iam_policy_document.cloudwatch-logs.json}"
}

# Currently idp and worker share an IAM instance profile. The worker servers
# need to be able to associate EIPs with themselves in order to assign
# themselves a static IP address.
# https://github.com/18F/identity-devops/pull/689
resource "aws_iam_role_policy" "idp-worker-auto-eip" {
  name = "${var.env_name}-idp-worker-auto-eip"
  role = "${aws_iam_role.idp.id}"
  policy = "${data.aws_iam_policy_document.auto_eip_policy.json}"
}

module "idp_launch_config" {
  source = "../terraform-modules/bootstrap/"

  role = "idp"
  env = "${var.env_name}"
  domain = "${var.root_domain}"

  chef_download_url = "${var.chef_download_url}"
  chef_download_sha256 = "${var.chef_download_sha256}"

  # identity-devops-private variables
  private_s3_ssh_key_url = "${var.bootstrap_private_s3_ssh_key_url}"
  private_git_clone_url = "${var.bootstrap_private_git_clone_url}"
  private_git_ref = "${var.bootstrap_private_git_ref}"

  # identity-devops variables
  main_s3_ssh_key_url = "${var.bootstrap_main_s3_ssh_key_url}"
  main_git_clone_url = "${var.bootstrap_main_git_clone_url}"
  main_git_ref = "${var.bootstrap_main_git_ref}"
}

# TODO it would be nicer to have this in the module, but the
# aws_launch_configuration and aws_autoscaling_group must be in the same module
# due to https://github.com/terraform-providers/terraform-provider-aws/issues/681
# See discussion in ../terraform-modules/bootstrap/vestigial.tf.txt
resource "aws_launch_configuration" "idp" {
  depends_on = ["aws_security_group.amazon_netblocks_ssl"]
  name_prefix = "${var.env_name}.idp.${var.bootstrap_main_git_ref}."

  lifecycle {
    create_before_destroy = true
  }

  image_id = "${var.idp1_ami_id}" # TODO switch to idp_ami_id
  instance_type = "${var.instance_type_idp}"
  security_groups = ["${aws_security_group.idp.id}","${aws_security_group.amazon_netblocks_ssl.id}"]

  user_data = "${module.idp_launch_config.rendered_cloudinit_config}"

  iam_instance_profile = "${aws_iam_instance_profile.idp.id}"
}

# For debugging cloud-init
#output "rendered_cloudinit_config" {
#  value = "${module.idp_launch_config.rendered_cloudinit_config}"
#}

resource "aws_autoscaling_group" "idp" {
    name = "${var.env_name}-idp"

    launch_configuration = "${aws_launch_configuration.idp.name}"

    min_size = "${var.asg_idp_min}"
    max_size = "${var.asg_idp_max}"
    desired_capacity = "${var.asg_idp_desired}"

    # Don't create an IDP ASG if we don't have an ALB.
    # We can't refer to aws_alb_target_group.idp unless it exists.
    count = "${var.alb_enabled}"

    target_group_arns = [
      "${aws_alb_target_group.idp.arn}",
      "${aws_alb_target_group.idp-ssl.arn}"
    ]

    vpc_zone_identifier = [
      "${aws_subnet.idp1.id}",
      "${aws_subnet.idp2.id}"
    ]

    # possible choices: EC2, ELB
    #health_check_type = "ELB"
    # For now, use an EC2 health check since bootstrapping takes so long and we
    # don't really want the ASG to terminate instances at all. (TODO)
    health_check_type = "EC2"

    # Currently bootstrapping seems to take 21-35 minutes, so we set the grace
    # period to 30 minutes. Ideally this would be *much* shorter.
    # https://github.com/18F/identity-devops-private/issues/337
    health_check_grace_period = 1800

    termination_policies = ["OldestInstance"]

    # Because bootstrapping takes so long, we terminate manually in prod
    # More context on ASG deploys and safety:
    # https://github.com/18F/identity-devops-private/issues/337
    protect_from_scale_in = "${var.asg_prevent_auto_terminate}"

    enabled_metrics = "${var.asg_enabled_metrics}"

    tag {
        key = "Name"
        value = "asg-${var.env_name}-idp"
        propagate_at_launch = true
    }
    tag {
        key = "client"
        value = "${var.client}"
        propagate_at_launch = true
    }
    tag {
        key = "prefix"
        value = "idp"
        propagate_at_launch = true
    }
    tag {
        key = "domain"
        value = "${var.env_name}.${var.root_domain}"
        propagate_at_launch = true
    }
}

module "idp_recycle" {
    source = "../terraform-modules/asg_recycle/"

    # switch to count when that's a thing that we can do
    # https://github.com/hashicorp/terraform/issues/953
    enabled = "${var.asg_auto_6h_recycle}"

    asg_name = "${aws_autoscaling_group.idp.name}"
    normal_desired_capacity = "${aws_autoscaling_group.idp.desired_capacity}"

    # TODO once we're on TF 0.10 remove these
    min_size = "${aws_autoscaling_group.idp.min_size}"
    max_size = "${aws_autoscaling_group.idp.max_size}"
}

resource "aws_route53_record" "idp-postgres" {
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name = "idp-postgres"

  type = "CNAME"
  ttl = "300"
  records = ["${replace(aws_db_instance.idp.endpoint,":5432","")}"]
}

resource "aws_route53_record" "redis" {
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name = "redis"

  type = "CNAME"
  ttl = "300"
  records = ["${aws_elasticache_cluster.idp.cache_nodes.0.address}"]
}
