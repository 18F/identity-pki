module "eks_admin_assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=5aa7231e4a3a91a9f4869311fbbaada99a72062b"
  #source = "../../../../identity-terraform/iam_assumerole"

  role_name                       = "EKSAdmin"
  enabled                         = contains(local.enabled_roles, "iam_eksadmin_enabled")
  master_assumerole_policy        = data.aws_iam_policy_document.master_account_assumerole.json
  custom_iam_policies             = var.dnssec_zone_exists ? [data.aws_iam_policy.dnssec_disable_prevent[0].name] : []
  permissions_boundary_policy_arn = aws_iam_policy.permissions_boundary.arn

  iam_policies = [
    {
      policy_name        = "EKSAdminPolicy"
      policy_description = "Policy for EKS administration"
      policy_document = [
        {
          sid    = "EKSAdminPermissions"
          effect = "Allow"
          actions = [
            "eks:DescribeCluster",
            "eks:ListClusters",
            "eks:AccessKubernetesApi",
            "eks:ListAccessEntries",
            "aps:ListScrapers",
            "eks:ListInsights",
          ]
          actions = [
            "eks:ListFargateProfiles",
            "eks:AccessKubernetesApi",
            "eks:AssociateAccessPolicy",
            "eks:AssociateEncryptionConfig",
            "eks:AssociateIdentityProviderConfig",
            "eks:CreateAccessEntry",
            "eks:CreateAddon",
            "eks:CreatePodIdentityAssociation",
            "eks:DeregisterCluster",
            "eks:DescribeAccessEntry",
            "eks:DescribeAddon",
            "eks:DescribeAddonConfiguration",
            "eks:DescribeAddonVersions",
            "eks:DescribeCluster",
            "eks:DescribeIdentityProviderConfig",
            "eks:DescribeInsight",
            "eks:DescribeNodegroup",
            "eks:DescribePodIdentityAssociation",
            "eks:DescribeUpdate",
            "eks:DisassociateAccessPolicy",
            "eks:DisassociateIdentityProviderConfig",
            "eks:ListAccessEntries",
            "eks:ListAccessPolicies",
            "eks:ListAddons",
            "eks:ListAssociatedAccessPolicies",
            "eks:ListClusters",
            "eks:ListIdentityProviderConfigs",
            "eks:ListInsights",
            "eks:ListNodegroups",
            "eks:ListPodIdentityAssociations",
            "eks:ListTagsForResource",
            "eks:ListUpdates",
            "eks:RegisterCluster",
            "eks:TagResource",
            "eks:UntagResource",
            "eks:UpdateAccessEntry",
            "eks:UpdateAddon",
            "eks:UpdateClusterConfig",
            "eks:UpdateClusterVersion",
            "eks:UpdateNodegroupConfig",
            "eks:UpdateNodegroupVersion",
            "eks:UpdatePodIdentityAssociation",
            "aps:ListScrapers",
          ]

          resources = [
            "*",
          ]
        },
      ]
    },
  ]
}