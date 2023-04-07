# Splunk OnCall SNS

Creates SNS topics to send alerts to Splunk OnCall.

Defines topics in the following regions:
* us-west-2
* us-east-1

You must specify the `splunk_oncall_routing_keys` variable with a map 
where keys each match a Routing Key in Splunk Oncall.
These keys are not secret and are used to route the alert
to the correct escalation policy.  The value of each map item is used to
label the SNS topic to help with navigation.

After first being applied a SSM Parameter secret string named
`/account/splunk_oncall/endpoint` will be created in `us-west-2` and `us-east-1`.

You must update these with with the first part of the "Service API Endpoint"
defined in Splunk OnCall in Integrations -> AWS CloudWatch.  Do not include
the trailing `/$routing_key` component which will be added per-instance.

Example Service API Endpoint:
~~~
https://alert.victorops.com/integrations/cloudwatch/20131130/alert/dead-beef/$routing_key
~~~

Example `/account/splunk_oncall/endpont` contents to match:
~~~
https://alert.victorops.com/integrations/cloudwatch/20131130/alert/dead-beef
~~~

Setting a new `/account/splunk_oncall/endpoint` value in both regions:
~~~sh
aws ssm put-parameter --region us-west-2 --overwrite --type SecureString \
  --name /account/splunk_oncall/endpoint --value '<SERVICE_API_ENDPOINT>'
aws ssm put-parameter --region us-east-1 --overwrite --type SecureString \
  --name /account/splunk_oncall/endpoint --value '<SERVICE_API_ENDPOINT>'
~~~
