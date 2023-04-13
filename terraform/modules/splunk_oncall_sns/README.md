# Splunk On-Call SNS

Creates SNS topics to send alerts to Splunk On-Call.

Defines topics in the region defined by the `aws` provider.

You must specify the `splunk_oncall_routing_keys` variable with a map 
where keys each match a Routing Key in Splunk Oncall.
These keys are not secret and are used to route the alert
to the correct escalation policy.  The value of each map item is used to
label the SNS topic to help with navigation.

After first being applied SSM Parameter secrets will be created:
* `/account/splunk_oncall/cloudwatch_endpoint` - Set to the first part of the "Service API Endpoint"
defined in Splunk On-Call in Integrations -> AWS CloudWatch (without `/$routing-key`)
* `/account/splunk_oncall/newrelic_endpoint` - Set to the first part of the "Service API Endpoint"
defined in Splunk On-Call in Integrations -> NewRelic (without `/$routing-key`)

You can either include the values as input variables or
update these secrets via CLI and re-apply terraform.

Example Service API Endpoint for CloudWatch:
~~~
https://alert.victorops.com/integrations/cloudwatch/20131130/alert/dead-beef/$routing_key
~~~

Example `/account/splunk_oncall/cloudwatch_endpoint` contents to match:
~~~
https://alert.victorops.com/integrations/cloudwatch/20131130/alert/dead-beef
~~~

Example: Setting a new `/account/splunk_oncall/cloudwatch_endpoint` value in `us-west-2`:
~~~sh
aws ssm put-parameter --region us-west-2 --overwrite --type SecureString \
  --name /account/splunk_oncall/cloudwatch_endpoint --value '<SERVICE_API_ENDPOINT>'
~~~

Once set, re-apply to update the SNS targets.  **If you do not re-apply after
setting the correct endpoint base URI in SSM Parameter Store, alerts will not
be delivered to Splunk On-Call!**


