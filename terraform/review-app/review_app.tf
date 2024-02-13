module "eks_cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.13"
  # EKS Control Plane
  cluster_name                    = var.cluster_name
  cluster_version                 = var.kubernetes_version
  vpc_id                          = module.vpc.vpc_id
  subnet_ids                      = module.vpc.private_subnets
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true
  enable_irsa                     = true


  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ReadOnly"
      username = "ReadOnly"
      groups   = ["read-only"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Analytics"
      username = "Analytics"
      groups   = ["read-only"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/FraudOps"
      username = "FraudOps"
      groups   = ["read-only"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/PowerUser"
      username = "PowerUser"
      groups   = ["review-app"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/FullAdministrator"
      username = "FullAdministrator"
      groups   = ["power-user"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/EKSAdmin"
      username = "EKSAdmin"
      groups   = ["eks-admin"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Terraform"
      username = "Terraform"
      groups   = ["terraform"]
    },
  ]

  # EKS Addons
  cluster_addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      # Specify the VPC CNI addon should be deployed before compute to ensure
      # the addon is configured before data plane compute resources are created
      # See README for further details
      before_compute = true
      most_recent    = true # To ensure access to the latest settings provided
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }

  # EKS Managed Node Group
  eks_managed_node_groups = {
    spot = {
      node_group_name = "${var.cluster_name}-managed-spot"
      min_size        = 1
      max_size        = 60
      desired_size    = 2
      subnet_ids      = module.vpc.private_subnets
      capacity_type   = "SPOT"
      instance_types  = ["m5.large", "m4.large", "m6a.large", "m5a.large", "m5d.large"] // Instances with same specs for memory and CPU so Cluster Autoscaler scales efficiently
      disk_size       = 100                                                             # disk_size will be ignored when using Launch Templates  
      # k8s_taints      = [{key= "spot", value="true", effect="NO_SCHEDULE"}]
    }
    ondemand = {
      node_group_name = "${var.cluster_name}-managed-ondemand"
      min_size        = 1
      max_size        = 2
      desired_size    = 1
      subnet_ids      = module.vpc.private_subnets
      capacity_type   = "ON_DEMAND"
      instance_types  = ["m5.large", "m4.large", "m6a.large", "m5a.large", "m5d.large"] // Instances with same specs for memory and CPU so Cluster Autoscaler scales efficiently
      disk_size       = 100                                                             # disk_size will be ignored when using Launch Templates
      k8s_taints      = [{ key = "ondemand", value = "true", effect = "NO_SCHEDULE" }]
    }
  }
  tags = local.tags
}
