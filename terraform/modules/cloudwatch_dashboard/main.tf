locals {
  sp_filter_variables = length(var.filter_sps) == 0 ? [] : [{
    "type" : "pattern",
    "pattern" : "ispresent\\(properties\\.service_provider\\) or not ispresent\\(properties\\.service_provider\\)",
    "inputType" : "select",
    "id" : "sp",
    "label" : "Service provider",
    "defaultValue" : "ispresent(properties.service_provider) or not ispresent(properties.service_provider)",
    "visible" : true,
    "values" : concat(
      [
        {
          "value" : "ispresent(properties.service_provider) or not ispresent(properties.service_provider)",
          "label" : "(All)"
        }
      ],
      [
        for sp in var.filter_sps :
        {
          "value" : join(" or ", [for issuer in sp.issuers : "properties.service_provider = ${jsonencode(issuer)}"]),
          "label" : sp.name
        }
      ]
    )
  }]


  dashboard_body = merge(
    var.dashboard_definition,
    {
      variables : concat(
        [
          # If the dashboard definition already contains an "sp" variable, remove it if we are going
          # to be replacing it.
          for v in coalesce(var.dashboard_definition.variables, []) : v if v.id != "sp" || length(local.sp_filter_variables) == 0
        ],
        local.sp_filter_variables
      )
    },
    {
      widgets : [
        for w in var.dashboard_definition.widgets :
        merge(
          w,
          {
            properties : merge(
              w.properties,
              
              # Update region referenced in dashboard JSON
              contains(keys(w.properties), "region") ? { region : var.region } : {},

              # Update environment referenced in query sources
              contains(keys(w.properties), "query") ? {
                query : replace(w.properties.query, "/^SOURCE '[a-z0-9]+_/", "SOURCE '${var.env_name}_")
              } : {}
            )
          }
        )
      ]
    }
  )
}

# resource "local_file" "cloudwatch_dashboard" {
#     filename = "dashboards/${var.env_name}-${var.dashboard_name}.json"
#     content = jsonencode(local.dashboard_body)
# }

resource "aws_cloudwatch_dashboard" "dashboard" {
  dashboard_name = "${var.env_name}-${var.dashboard_name}"
  dashboard_body = jsonencode(local.dashboard_body)
}
