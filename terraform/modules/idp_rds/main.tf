terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  pgroup_family = join("", [var.db_engine, split(".", var.db_engine_version)[0]])
  db_name = var.db_name_override == "" ? (
  "${var.env_name}-${var.db_identifier}") : var.db_name_override
  db_name_prefix = join("-", [
    var.name, var.env_name, var.db_identifier, local.pgroup_family, ""
  ])
}

## parameter groups below will be created IFF their corresponding var isn't empty ##

# RDS (used by gitlab DBs)

resource "aws_db_parameter_group" "force_ssl" {
  count       = length(var.pgroup_params) > 0 ? 1 : 0
  name_prefix = local.db_name_prefix

  # Before changing this value, make sure the parameters are correct for the
  # version you are upgrading to.  See
  # http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.html.
  family = local.pgroup_family

  # Setting to 30 minutes, RDS requires value in ms
  # https://aws.amazon.com/blogs/database/best-practices-for-amazon-rds-postgresql-replication/
  parameter {
    name  = "max_standby_archive_delay"
    value = "1800000"
  }

  dynamic "parameter" {
    for_each = var.pgroup_params
    iterator = pblock

    content {
      name         = pblock.value.name
      value        = pblock.value.value
      apply_method = lookup(pblock.value, "method", "immediate")
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Aurora (used by idp/worker/dashboard DBs)

resource "aws_rds_cluster_parameter_group" "aurora" {
  count       = length(var.cluster_pgroup_params) > 0 ? 1 : 0
  name        = "${local.db_name}-${local.pgroup_family}-cluster"
  family      = local.pgroup_family
  description = "${local.pgroup_family} parameter group for ${local.db_name} cluster"

  dynamic "parameter" {
    for_each = var.cluster_pgroup_params
    iterator = pblock

    content {
      name         = pblock.value.name
      value        = pblock.value.value
      apply_method = lookup(pblock.value, "method", "immediate")
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_parameter_group" "aurora" {
  count       = length(var.db_pgroup_params) > 0 ? 1 : 0
  name        = "${local.db_name}-${local.pgroup_family}-db"
  family      = local.pgroup_family
  description = "${local.pgroup_family} parameter group for ${local.db_name} instances"

  dynamic "parameter" {
    for_each = var.db_pgroup_params
    iterator = pblock

    content {
      name         = pblock.value.name
      value        = pblock.value.value
      apply_method = lookup(pblock.value, "method", "immediate")
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}
