resource "aws_cloudwatch_dashboard" "idp_idv_errors" {
  dashboard_name = "${var.env_name}-idp-idv-errors"
  dashboard_body = jsonencode({
    "widgets" : [
      {
        "height" : 1,
        "width" : 24,
        "y" : 0,
        "x" : 0,
        "type" : "text",
        "properties" : {
          "markdown" : "# [![](https://login.gov/assets/img/logo.svg) Bizops Dashboard](#dashboards:name=bizops-dashboard) - IdV Errors\n"
        }
      },
      {
        "height" : 11,
        "width" : 12,
        "y" : 1,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE 'prod_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| sort @timestamp desc\n| filter properties.path like '/verify'\n| filter properties.event_properties.success = 0\n| filter properties.event_properties.vendor = 'Acuant'| filter ispresent(properties.event_properties.errors.general.0)\n| stats count(*) as Total by properties.event_properties.errors.general.0 as Error\n| sort Total desc\n",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "Acuant DocAuth Errors",
          "view" : "table"
        }
      },
      {
        "height" : 11,
        "width" : 12,
        "y" : 1,
        "x" : 12,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE 'prod_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| sort @timestamp desc\n| filter properties.path like '/verify'\n| filter properties.event_properties.success = 0\n| filter properties.event_properties.vendor = 'TrueID'| filter ispresent(properties.event_properties.errors.general.0)\n| stats count(*) as Total by properties.event_properties.errors.general.0 as Error\n| sort Total desc\n",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "TrueID DocAuth Errors",
          "view" : "table"
        }
      },
      {
        "height" : 1,
        "width" : 24,
        "y" : 12,
        "x" : 0,
        "type" : "text",
        "properties" : {
          "markdown" : "### LexisNext Instant Verify Errors\n"
        }
      },
      {
        "height" : 3,
        "width" : 4,
        "y" : 13,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE 'prod_/srv/idp/shared/log/events.log' | filter (\n (name = 'IdV: doc auth optional verify_wait submitted' and !properties.event_properties.success and\n `properties.event_properties.errors.Execute Instant Verify.0.ProductStatus`='fail' and \n `properties.event_properties.errors.Execute Instant Verify.0.Items.0.ItemStatus` = 'fail')\n)\n| stats count(*) as Total\n",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "Addr1Zip_StateMatch",
          "view" : "table"
        }
      },
      {
        "height" : 3,
        "width" : 4,
        "y" : 13,
        "x" : 4,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE 'prod_/srv/idp/shared/log/events.log' | filter (\n (name = 'IdV: doc auth optional verify_wait submitted' and !properties.event_properties.success and\n `properties.event_properties.errors.Execute Instant Verify.0.ProductStatus`='fail' and \n `properties.event_properties.errors.Execute Instant Verify.0.Items.1.ItemStatus` = 'fail')\n)\n| stats count(*) as Total\n",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "SsnFullNameMatch",
          "view" : "table"
        }
      },
      {
        "height" : 3,
        "width" : 5,
        "y" : 13,
        "x" : 8,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE 'prod_/srv/idp/shared/log/events.log' | filter (\n (name = 'IdV: doc auth optional verify_wait submitted' and !properties.event_properties.success and\n `properties.event_properties.errors.Execute Instant Verify.0.ProductStatus`='fail' and \n `properties.event_properties.errors.Execute Instant Verify.0.Items.2.ItemStatus` = 'fail')\n)\n| stats count(*) as Total\n",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "SsnDeathMatchVerification",
          "view" : "table"
        }
      },
      {
        "height" : 3,
        "width" : 4,
        "y" : 13,
        "x" : 13,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE 'prod_/srv/idp/shared/log/events.log' | filter (\n (name = 'IdV: doc auth optional verify_wait submitted' and !properties.event_properties.success and\n `properties.event_properties.errors.Execute Instant Verify.0.ProductStatus`='fail' and \n `properties.event_properties.errors.Execute Instant Verify.0.Items.3.ItemStatus` = 'fail')\n)\n| stats count(*) as Total\n",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "SSNSSAValid",
          "view" : "table"
        }
      },
      {
        "height" : 3,
        "width" : 5,
        "y" : 13,
        "x" : 17,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE 'prod_/srv/idp/shared/log/events.log' | filter (\n (name = 'IdV: doc auth optional verify_wait submitted' and !properties.event_properties.success and\n `properties.event_properties.errors.Execute Instant Verify.0.ProductStatus`='fail' and \n `properties.event_properties.errors.Execute Instant Verify.0.Items.4.ItemStatus` = 'fail')\n)\n| stats count(*) as Total\n",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "IdentityOccupancyVerified",
          "view" : "table"
        }
      },
      {
        "height" : 3,
        "width" : 4,
        "y" : 16,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE 'prod_/srv/idp/shared/log/events.log' | filter (\n (name = 'IdV: doc auth optional verify_wait submitted' and !properties.event_properties.success and\n `properties.event_properties.errors.Execute Instant Verify.0.ProductStatus`='fail' and \n `properties.event_properties.errors.Execute Instant Verify.0.Items.5.ItemStatus` = 'fail')\n)\n| stats count(*) as Total\n",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "AddrDeliverable",
          "view" : "table"
        }
      },
      {
        "height" : 3,
        "width" : 4,
        "y" : 16,
        "x" : 4,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE 'prod_/srv/idp/shared/log/events.log' | filter (\n (name = 'IdV: doc auth optional verify_wait submitted' and !properties.event_properties.success and\n `properties.event_properties.errors.Execute Instant Verify.0.ProductStatus`='fail' and \n `properties.event_properties.errors.Execute Instant Verify.0.Items.6.ItemStatus` = 'fail')\n)\n| stats count(*) as Total\n",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "AddrNotHighRisk",
          "view" : "table"
        }
      },
      {
        "height" : 3,
        "width" : 4,
        "y" : 16,
        "x" : 8,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE 'prod_/srv/idp/shared/log/events.log' | filter (\n (name = 'IdV: doc auth optional verify_wait submitted' and !properties.event_properties.success and\n `properties.event_properties.errors.Execute Instant Verify.0.ProductStatus`='fail' and \n `properties.event_properties.errors.Execute Instant Verify.0.Items.7.ItemStatus` = 'fail')\n)\n| stats count(*) as Total\n",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "DOBFullVerified",
          "view" : "table"
        }
      },
      {
        "height" : 3,
        "width" : 4,
        "y" : 16,
        "x" : 12,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE 'prod_/srv/idp/shared/log/events.log' | filter (\n (name = 'IdV: doc auth optional verify_wait submitted' and !properties.event_properties.success and\n `properties.event_properties.errors.Execute Instant Verify.0.ProductStatus`='fail' and \n `properties.event_properties.errors.Execute Instant Verify.0.Items.8.ItemStatus` = 'fail')\n)\n| stats count(*) as Total\n",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "DOBYearVerified",
          "view" : "table"
        }
      },
      {
        "height" : 3,
        "width" : 4,
        "y" : 16,
        "x" : 16,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE 'prod_/srv/idp/shared/log/events.log' | filter (\n (name = 'IdV: doc auth optional verify_wait submitted' and !properties.event_properties.success and\n `properties.event_properties.errors.Execute Instant Verify.0.ProductStatus`='fail' and \n `properties.event_properties.errors.Execute Instant Verify.0.Items.9.ItemStatus` = 'fail')\n)\n| stats count(*) as Total\n",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "LexIDDeathMatch",
          "view" : "table"
        }
      },
      {
        "height" : 3,
        "width" : 24,
        "y" : 19,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE 'prod_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| sort @timestamp desc\n| filter name = \"IdV: phone confirmation vendor\"\n| filter properties.path like '/verify'\n| filter properties.event_properties.success = 0\n| filter ispresent(`properties.event_properties.errors.PhoneFinder Checks.0.ProductReason.Description`)\n| stats count(*) as Total by `properties.event_properties.errors.PhoneFinder Checks.0.ProductReason.Description` as Error\n| sort Total desc",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "LexisNexis Phone Finder Errors",
          "view" : "table"
        }
      }
    ]
  })
}
