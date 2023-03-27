resource "aws_cloudwatch_dashboard" "idp_sp_dashboards" {
  for_each = var.idp_sp_dashboards

  dashboard_name = "${var.env_name}-SPDashboards-${each.value["agency"]}-${each.value["name"]}"
  dashboard_body = jsonencode({
    "widgets" : [
      {
        "type" : "metric",
        "x" : 6,
        "y" : 0,
        "width" : 6,
        "height" : 6,
        "properties" : {
          "metrics" : [
            ["${var.env_name}/idp-authentication", "user-marked-authenticated-sp", "service_provider", each.value["issuer"], {
              "label" : each.value["issuer"]
            }],
          ],
          "view" : "timeSeries",
          "stacked" : false,
          "region" : var.region,
          "stat" : "Sum",
          "period" : 60,
          "title" : "User authentications / min",
        }
      },
      {
        "type" : "metric",
        "x" : 0,
        "y" : 6,
        "width" : 6,
        "height" : 6,
        "properties" : {
          "metrics" : [
            ["${var.env_name}/idp-authentication", "sp-redirect-initiated", "service_provider", each.value["issuer"], {
              "label" : each.value["issuer"]
            }],
          ],
          "view" : "timeSeries",
          "stacked" : false,
          "region" : var.region,
          "stat" : "Sum",
          "period" : 60,
          "title" : "SP Redirects / min",
        }
      },
      {
        "type" : "metric",
        "x" : 0,
        "y" : 0,
        "width" : 6,
        "height" : 6,
        "properties" : {
          "metrics" : [
            ["${var.env_name}/idp-authentication", "user-registration-complete-sp", "service_provider", each.value["issuer"], {
              "label" : each.value["issuer"]
            }],
          ],
          "view" : "timeSeries",
          "stacked" : false,
          "region" : var.region,
          "stat" : "Sum",
          "period" : 60,
          "title" : "User registration completions / min",
        }
      },
      {
        "type" : "metric",
        "x" : 6,
        "y" : 6,
        "width" : 6,
        "height" : 6,
        "properties" : {
          "metrics" : [
            ["${var.env_name}/idp-ialx", "idv-final-resolution-success", "service_provider", each.value["issuer"], {
              "label" : each.value["issuer"]
            }],
          ],
          "view" : "timeSeries",
          "stacked" : false,
          "region" : var.region,
          "stat" : "Sum",
          "period" : 60,
          "title" : "IdV: Final Resolutions / min",
        }
      }
    ]
  })
}
