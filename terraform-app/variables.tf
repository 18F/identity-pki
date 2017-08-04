variable "app_sg_ssh_cidr_blocks" { type="list" }
variable "power_users" { type="list" }
variable "admin_subnet_cidr_block" { default = "172.16.33.16/28"} # 172.16.33.16 - 172.16.33.31
variable "app1_subnet_cidr_block"  { default = "172.16.33.96/28" } # 172.16.33.96 - 172.16.33.111
variable "spare_subnet_cidr_block"  { default = "172.16.33.112/28" } # 172.16.33.112 - 172.16.33.115
variable "db1_subnet_cidr_block"  { default = "172.16.33.32/28" } # 172.16.33.32 - 172.16.33.47
variable "db2_subnet_cidr_block"  { default = "172.16.33.48/28"} # 172.16.33.48 - 172.16.33.63
variable "db3_subnet_cidr_block"  { default = "172.16.33.64/28"} # 172.16.33.64 - 172.16.33.79
variable "chef_subnet_cidr_block"  { default = "172.16.33.80/28"} # 172.16.33.80 - 172.16.33.96
variable "idp1_subnet_cidr_block"  { default = "172.16.33.128/27" } # 172.16.33.128 - 172.16.33.159
variable "idp2_subnet_cidr_block"  { default = "172.16.33.160/27" } # 172.16.33.160 - 172.16.33.191
variable "idp3_subnet_cidr_block"  { default = "172.16.33.192/27" } # 172.16.33.192 - 172.16.33.223
variable "alb1_subnet_cidr_block"  { default = "172.16.33.224/28" } # 172.16.33.224 - 172.16.33.239
variable "alb2_subnet_cidr_block"  { default = "172.16.33.240/28" } # 172.16.33.240 - 172.16.33.255
variable "jumphost_subnet_cidr_block" { default = "172.16.33.0/28"} # 172.16.33.1 - 172.16.33.15
variable "vpc_cidr_block"         { default = "172.16.32.0/22" } # 172.16.32.0 - 172.16.35.255
#variable "vpc_cidr_block"         { default = "172.16.33.0/24" } # 172.16.32.0 - 172.16.35.255


variable "ami_id" {}
variable "default_ami_id" {}
variable "jenkins_ami_id" {}
variable "chef_ami_id" {}
variable "chef_home" {}
variable "jumphost_ami_id" {}
variable "idp1_ami_id" {}
variable "idp2_ami_id" {}
variable "worker_ami_id" {}
variable "worker_ami_list" { type="list" }
variable "route53_id" {}
variable "apps_enabled" { default = false }

# https://downloads.chef.io/chef/stable/12.15.19#ubuntu
variable "chef_version" { default = "12.15.19" }
variable "chef_download_url" {
    default = "https://packages.chef.io/files/stable/chef/12.15.19/ubuntu/16.04/chef_12.15.19-1_amd64.deb"
}
variable "chef_download_sha256" {
    default = "7073541beb4294c994d4035a49afcf06ab45b3b3933b98a65b8059b7591df6b8"
}

variable "chef_url" { default = "https://chef.login.gov.internal/organizations/login-dev" }
variable "chef_databag_key_path" {}
variable "chef_id" {}
variable "chef_info" {}
variable "chef_id_key_path" {}
variable "chef_repo_gitref" { default = "master" }
variable "client" {}
variable "env_name" { default = "tf" }
variable "esnodes" { default = 2 }
variable "git_deploy_key_path" {}
variable "idp_node_count" { default = 1 }
variable "idp_worker_count" { default = 2 }
variable "instance_type_app" { default = "t2.medium" }
variable "instance_type_chef" { default = "t2.medium" }
variable "instance_type_elk" { default = "t2.medium" }
variable "instance_type_idp" { default = "t2.medium" }
variable "instance_type_jenkins" { default = "t2.medium" }
variable "instance_type_jumphost" { default = "t2.small" }
variable "instance_type_worker" { default = "t2.small" }
variable "key_name" {}
variable "live_certs" {}
variable "name" { default = "login" }
variable "region" { default = "us-west-2" }
variable "version_info_bucket" { default = "login_dot_gov_tf_state" }
variable "version_info_region" { default = "us-east-1" }

# Auto scaling group desired counts
variable "asg_jumphost_desired" { default = 0 }
variable "asg_idp_desired" { default = 0 }
variable "asg_worker_desired" { default = 0 }

# Several variables used by the terraform-modules/bootstrap/ module for running
# provision.sh to clone git repos and run chef.
variable "bootstrap_main_git_ref" {
    default = "HEAD"
    description = "Git ref in identity-devops for provision.sh to check out"
}
variable "bootstrap_main_s3_ssh_key_url" {
    default = "s3://login-gov-secrets-test/common/id_ecdsa.identity-devops.deploy"
    description = "S3 path to find an SSH key for cloning identity-devops"
}
variable "bootstrap_main_git_clone_url" {
    default = "git@github.com:18F/identity-devops"
    description = "URL for provision.sh to use to clone identity-devops"
}
variable "bootstrap_private_git_ref" {
    default = "HEAD"
    description = "Git ref in identity-devops for provision.sh to check out"
}
variable "bootstrap_private_s3_ssh_key_url" {
    default = "s3://login-gov-secrets-test/common/id_ecdsa.id-do-private.deploy"
    description = "S3 path to find an SSH key for cloning identity-devops-private"
}
variable "bootstrap_private_git_clone_url" {
    default = "git@github.com:18F/identity-devops-private"
    description = "URL for provision.sh to use to clone identity-devops-private"
}

# These variables are used both to create the continuous integration VPC (a
# VPC with only base services like the Postgres and Redis, so that nodes can be
# integration tested), and to help with migration one node at a time to
# autoscaled nodes that do not need a chef server to bootstrap.
#
# NOTE: These must be numbers, as terraform does not support boolean values,
# only numbers and strings.
#
# See: https://blog.gruntwork.io/terraform-tips-tricks-loops-if-statements-and-gotchas-f739bbae55f9

variable "non_asg_jumphost_enabled" {
    default = 1
    description = "Enable non autoscaled jumphost node"
}

variable "non_asg_jenkins_enabled" {
    default = 1
    description = "Enable non autoscaled jenkins node"
}

variable "non_asg_idp_enabled" {
    default = 1
    description = "Enable non autoscaled idp node"
}

variable "non_asg_idp_worker_enabled" {
    default = 1
    description = "Enable non autoscaled idp worker node"
}

variable "non_asg_es_enabled" {
    default = 1
    description = "Enable non autoscaled elasticsearch nodes"
}

variable "non_asg_elk_enabled" {
    default = 1
    description = "Enable non autoscaled elk node"
}

variable "chef_server_enabled" {
    default = 1
    description = "Enable Chef Server node"
}

variable "alb_enabled" {
    default = 1
    description = "Enable ALB for idp hosts"
}

# This variable is needed for service discovery

variable "certificates_bucket_name_prefix" {
    description = "Base name for the self signed certificates bucket used for service discovery"
    default = "login-gov-internal-certs-test"
}
