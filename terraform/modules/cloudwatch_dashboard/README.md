# cloudwatch_dashboard

This module will create a dashboard in Amazon Cloudwatch.

Use this module like this:

```terraform
module "my-dashboard-name" {
    source = "../modules/cloudwatch_dashboard"

    dashboard_name = "my-dashboard-name"
    
    # filter_sps is used to set up a variable, "sp", that provides a dropdown for SP selelection
    filter_sps = [
        {
            name = "OIDC Sinatra App"
            issuers = [ "" ]
        }
    ]

    dashboard_definition = {
        # Here is where you paste in the JSON you got from Cloudwatch.
        # Alternately, you could put it in a .json file and use the `local_file` data source.
    }

} 
```

## Using the SP filter

The SP filter is based on [Variables][cloudwatch-variables], a kind of clunky feature of Cloudwatch dashboards. Basically, it does a find-and-replace on the _JSON representation_ of your dashboard based on the variable(s) you choose.

To implement an SP filter in your dashboard, first add the following to the queries _all_ of your widgets that should be filtered by SP:

```cloudwatch
| filter ispresent(properties.service_provider) or not ispresent(properties.service_provider)
```

Add exactly this, on its own line. By default, this is a no-op--it will not filter by SP.

Then, specify the SPs you want to be available to filter by via the `filter_sps` variable:

```terraform
    filter_sps = [
        {
            "name" : "Example Sinatra App"
            "issuers" : [ "urn:gov:gsa:openidconnect:sp:sinatra" ]
        }
    ]
```

(Note that `issuers` is an array--the data model supports a single SP with multiple different issuer values if needed.)

[cloudwatch-variables]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_dashboard_variables.html