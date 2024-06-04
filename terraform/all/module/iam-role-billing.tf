module "billing-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=5aa7231e4a3a91a9f4869311fbbaada99a72062b"
  #source = "../../../../identity-terraform/iam_assumerole"

  role_name                       = "BillingReadOnly"
  enabled                         = contains(local.enabled_roles, "iam_billing_enabled")
  master_assumerole_policy        = data.aws_iam_policy_document.master_account_assumerole.json
  custom_iam_policies             = var.dnssec_zone_exists ? [data.aws_iam_policy.dnssec_disable_prevent[0].name] : []
  permissions_boundary_policy_arn = aws_iam_policy.permissions_boundary.arn

  # https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/migrate-granularaccess-iam-mapping-reference.html#mapping-for-aws-portalviewbilling
  iam_policies = [
    {
      policy_name        = "BillingReadOnly"
      policy_description = "Policy for reporting group read-only access to Billing ui"
      policy_document = [
        {
          sid    = "BillingReadOnly"
          effect = "Allow"
          actions = [
            "account:GetAccountInformation",
            "billing:GetBillingData",
            "billing:GetBillingDetails",
            "billing:GetBillingNotifications",
            "billing:GetBillingPreferences",
            "billing:GetContractInformation",
            "billing:GetCredits",
            "billing:GetIAMAccessPreference",
            "billing:GetSellerOfRecord",
            "billing:ListBillingViews",
            "ce:DescribeNotificationSubscription",
            "ce:DescribeReport",
            "ce:GetAnomalies",
            "ce:GetAnomalyMonitors",
            "ce:GetAnomalySubscriptions",
            "ce:GetCostAndUsage",
            "ce:GetCostAndUsageWithResources",
            "ce:GetCostCategories",
            "ce:GetCostForecast",
            "ce:GetDimensionValues",
            "ce:GetPreferences",
            "ce:GetReservationCoverage",
            "ce:GetReservationPurchaseRecommendation",
            "ce:GetReservationUtilization",
            "ce:GetRightsizingRecommendation",
            "ce:GetSavingsPlansCoverage",
            "ce:GetSavingsPlansPurchaseRecommendation",
            "ce:GetSavingsPlansUtilization",
            "ce:GetSavingsPlansUtilizationDetails",
            "ce:GetTags",
            "ce:GetUsageForecast",
            "ce:ListCostAllocationTags",
            "ce:ListSavingsPlansPurchaseRecommendationGeneration",
            "consolidatedbilling:GetAccountBillingRole",
            "consolidatedbilling:ListLinkedAccounts",
            "cur:GetClassicReport",
            "cur:GetClassicReportPreferences",
            "cur:ValidateReportDestination",
            "freetier:GetFreeTierAlertPreference",
            "freetier:GetFreeTierUsage",
            "invoicing:GetInvoiceEmailDeliveryPreferences",
            "invoicing:GetInvoicePDF",
            "invoicing:ListInvoiceSummaries",
            "payments:GetPaymentInstrument",
            "payments:GetPaymentStatus",
            "payments:ListPaymentPreferences",
            "tax:GetTaxInheritance",
            "tax:GetTaxRegistrationDocument",
            "tax:ListTaxRegistrations"
          ]
          resources = [
            "*",
          ]
        }
      ]
    },
  ]
}

### TODO: set this up and figure out enforcement in a future PR
#resource "aws_iam_role_policy" "ssm_nondoc_deny_billing" {
#  count = sum([
#    contains(keys(var.ssm_access_map),"BillingReadOnly") ? 0 : 1,
#    length(keys(var.ssm_access_map)) == 0 ? 0 : 1
#  ]) == 2 ? 1 : 0
#  
#  name        = "BillingReadOnly-SSMNonDocDeny"
#  role        = "BillingReadOnly"
#  policy      = data.aws_iam_policy_document.ssm_nondoc_deny.json
#}
