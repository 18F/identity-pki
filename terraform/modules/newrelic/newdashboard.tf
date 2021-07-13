
resource "newrelic_one_dashboard" "error_dashboard" {
  count = var.enabled
  
  name        = "Errors for ${var.error_dashboard_site}"
  permissions = "public_read_only"

  page {
    name = "Errors for ${var.error_dashboard_site}"

    widget_area {
      title  = "Errors by Service Provider"
      row    = 1
      column = 1
      height = 3
      width  = 4

      nrql_query {
        account_id = 1376370
        query      = "SELECT count(*) FROM TransactionError FACET service_provider WHERE appName = '${var.error_dashboard_site}' TIMESERIES"
      }
    }

    widget_area {
      title = "Errors by Endpoint"
      row = 1
      column = 5
      height = 3
      width = 4

      nrql_query {
        account_id = 1376370
        query      = "SELECT count(*) FROM TransactionError FACET transactionName WHERE appName = '${var.error_dashboard_site}' TIMESERIES"
      }
    }

    widget_area {
      title = "Errors by IAL level"
      row = 4
      column = 1
      height = 3
      width = 4

      nrql_query {
        account_id = 1376370
        query      = "SELECT count(*) FROM TransactionError FACET CASES (WHERE transactionName LIKE 'Controller/idv/%' AS IAL2, WHERE transactionName NOT LIKE 'Controller/idv/%' AS IAL1) WHERE appName = '${var.error_dashboard_site}' TIMESERIES"
      }
    }

    widget_table {
      title = "Errors Count"
      row = 4
      column = 5
      height = 3
      width = 8

      nrql_query {
        account_id = 1376370
        query      = "SELECT COUNT(*), uniques(error.message) FROM TransactionError WHERE appName = '${var.error_dashboard_site}' FACET error.class"
      }
    }
  }
}
