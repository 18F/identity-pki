resource "aws_codebuild_project" "base_image" {
  name           = local.base_codebuild_name
  description    = "Template to create resources for CodeBuild Project integrated with Git2S3"
  build_timeout  = "90"
  queued_timeout = "480"

  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
  }

  vpc_config {
    vpc_id = var.vpc_id

    subnets = [
      var.private_subnet_id,
    ]

    security_group_ids = [
      aws_security_group.main.id
    ]
  }

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/standard:6.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "ACCOUNT"
      value = var.account_name
    }

    environment_variable {
      name  = "AMI_NAME"
      value = "login.gov Base role hardened image ${var.packer_config["os_version"]} - ${var.env_name}"
    }

    environment_variable {
      name  = "AMI_DESCRIPTION"
      value = "CIS hardened image based on ${var.packer_config["os_version"]}"
    }

    environment_variable {
      name  = "AMI_OWNER_ID"
      value = var.packer_config["ami_owner_id"]
    }

    environment_variable {
      name  = "AMI_FILTER_NAME"
      value = var.packer_config["ami_filter_name"]
    }

    environment_variable {
      name  = "BERKSHELF_VERSION"
      value = var.packer_config["berkshelf_version"]
    }

    environment_variable {
      name  = "CHEF_ROLE"
      value = "base"
    }

    environment_variable {
      name  = "CHEF_VERSION"
      value = var.packer_config["chef_version"]
    }

    environment_variable {
      name  = "DATA_VOL_SIZE"
      value = var.packer_config["data_vol_size"]
    }

    environment_variable {
      name  = "DELETE_AMI_SNAPSHOTS"
      value = var.packer_config["deregister_existing_ami"]
    }

    environment_variable {
      name  = "DEREGISTER_EXISTING_AMI"
      value = var.packer_config["delete_ami_snapshots"]
    }

    environment_variable {
      name  = "ENCRYPTION"
      value = var.packer_config["encryption"]
    }

    environment_variable {
      name  = "OS_VERSION"
      value = var.packer_config["os_version"]
    }

    environment_variable {
      name  = "IAM_INSTANCE_PROFILE"
      value = aws_iam_instance_profile.packer.name
    }

    environment_variable {
      name  = "PACKER_VERSION"
      value = var.packer_config["packer_version"]
    }

    environment_variable {
      name  = "PACKER_LOG"
      value = "1"
    }

    environment_variable {
      name  = "PACKER_LOG_PATH"
      value = "build.log"
    }

    environment_variable {
      name  = "ROOT_VOL_SIZE"
      value = var.packer_config["root_vol_size"]
    }

    environment_variable {
      name  = "SECURITY_GROUP_ID"
      value = aws_security_group.main.id
    }

    environment_variable {
      name  = "SUBNET_ID"
      value = var.private_subnet_id
    }

    environment_variable {
      name  = "UBUNTU_VERSION"
      value = var.packer_config["ubuntu_major_version"]
    }

    environment_variable {
      name  = "VPC_ID"
      value = var.vpc_id
    }

    environment_variable {
      name  = "ASSOCIATE_PUBLIC_IP"
      value = var.associate_public_ip
    }

    environment_variable {
      name  = "AWS_POLL_DELAY_SECONDS"
      value = var.packer_config["delay_seconds"]
    }

    environment_variable {
      name  = "AWS_MAX_ATTEMPTS"
      value = var.packer_config["max_attempts"]
    }

    environment_variable {
      name  = "AWS_REGION"
      value = data.aws_region.current.name
    }

    environment_variable {
      name  = "AWS_INSTANCE_TYPE"
      value = var.packer_config["instance_type"]
    }

    environment_variable {
      name  = "AMI_COPY_REGION"
      value = var.ami_copy_region
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.imagebuild_base.name
    }
  }

  source {
    type      = "S3"
    location  = "${var.git2s3_bucket_name}/${local.identity_base_image_zip_s3_path}"
    buildspec = "buildspec-terraform.yml"
  }

  lifecycle {
    ignore_changes = [
      tags,
      tags_all
    ]
  }
}

resource "aws_codebuild_project" "rails_image" {
  name           = local.rails_codebuild_name
  description    = "Template to create resources for CodeBuild Project integrated with Git2S3"
  build_timeout  = "90"
  queued_timeout = "480"

  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  vpc_config {
    vpc_id = var.vpc_id

    subnets = [
      var.private_subnet_id,
    ]

    security_group_ids = [
      aws_security_group.main.id
    ]
  }

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/standard:6.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "ACCOUNT"
      value = var.account_name
    }

    environment_variable {
      name  = "AMI_NAME"
      value = "login.gov Rails role hardened image ${var.packer_config["os_version"]} - ${var.env_name}"
    }

    environment_variable {
      name  = "AMI_DESCRIPTION"
      value = "CIS hardened image based on ${var.packer_config["os_version"]}"
    }

    environment_variable {
      name  = "AMI_OWNER_ID"
      value = var.packer_config["ami_owner_id"]
    }

    environment_variable {
      name  = "AMI_FILTER_NAME"
      value = var.packer_config["ami_filter_name"]
    }

    environment_variable {
      name  = "BERKSHELF_VERSION"
      value = var.packer_config["berkshelf_version"]
    }

    environment_variable {
      name  = "CHEF_ROLE"
      value = "rails"
    }

    environment_variable {
      name  = "CHEF_VERSION"
      value = var.packer_config["chef_version"]
    }

    environment_variable {
      name  = "DATA_VOL_SIZE"
      value = var.packer_config["data_vol_size"]
    }

    environment_variable {
      name  = "DELETE_AMI_SNAPSHOTS"
      value = var.packer_config["deregister_existing_ami"]
    }

    environment_variable {
      name  = "DEREGISTER_EXISTING_AMI"
      value = var.packer_config["delete_ami_snapshots"]
    }

    environment_variable {
      name  = "ENCRYPTION"
      value = var.packer_config["encryption"]
    }

    environment_variable {
      name  = "OS_VERSION"
      value = var.packer_config["os_version"]
    }

    environment_variable {
      name  = "IAM_INSTANCE_PROFILE"
      value = aws_iam_instance_profile.packer.name
    }

    environment_variable {
      name  = "PACKER_VERSION"
      value = var.packer_config["packer_version"]
    }

    environment_variable {
      name  = "PACKER_LOG"
      value = "1"
    }

    environment_variable {
      name  = "PACKER_LOG_PATH"
      value = "build.log"
    }

    environment_variable {
      name  = "ROOT_VOL_SIZE"
      value = var.packer_config["root_vol_size"]
    }

    environment_variable {
      name  = "SECURITY_GROUP_ID"
      value = aws_security_group.main.id
    }

    environment_variable {
      name  = "SUBNET_ID"
      value = var.private_subnet_id
    }

    environment_variable {
      name  = "UBUNTU_VERSION"
      value = var.packer_config["ubuntu_major_version"]
    }

    environment_variable {
      name  = "VPC_ID"
      value = var.vpc_id
    }

    environment_variable {
      name  = "ASSOCIATE_PUBLIC_IP"
      value = var.associate_public_ip
    }

    environment_variable {
      name  = "AWS_POLL_DELAY_SECONDS"
      value = var.packer_config["delay_seconds"]
    }

    environment_variable {
      name  = "AWS_MAX_ATTEMPTS"
      value = var.packer_config["max_attempts"]
    }

    environment_variable {
      name  = "AWS_REGION"
      value = data.aws_region.current.name
    }

    environment_variable {
      name  = "AWS_INSTANCE_TYPE"
      value = var.packer_config["instance_type"]
    }

    environment_variable {
      name  = "AMI_COPY_REGION"
      value = var.ami_copy_region
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.imagebuild_rails.name
    }
  }

  source {
    type      = "S3"
    location  = "${var.git2s3_bucket_name}/${local.identity_base_image_zip_s3_path}"
    buildspec = "buildspec-terraform.yml"
  }

  lifecycle {
    ignore_changes = [
      tags,
      tags_all
    ]
  }
}