module "eks_admin_assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"

  role_name                       = "EKSAdmin"
  enabled                         = var.iam_account_alias == "login-prod" || var.iam_account_alias == "login-sandbox" ? true : false
  master_assumerole_policy        = data.aws_iam_policy_document.master_account_assumerole.json
  permissions_boundary_policy_arn = var.permission_boundary_policy_name != "" ? data.aws_iam_policy.permission_boundary_policy[0].arn : ""

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