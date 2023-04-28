# Special billing resources for payer account

# TODO - Break accounts into units to group
#data "aws_organizations_organization" "main" {}

#resource "aws_organizations_organizational_unit" "bu" {
#  name      = var.name
#  parent_id = data.aws_organizations_organization.main.roots.0.id
#}

resource "aws_budgets_budget" "aggregate" {
  name = "login-budget-all"

  budget_type = "COST"
  limit_unit  = "USD"
  # for some reason it adds a single decimal
  limit_amount      = "${var.budget_monthly_all}.0"
  time_period_start = "2019-11-07_00:00"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 95
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.billing_email_list
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 95
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.billing_email_list
  }
}
