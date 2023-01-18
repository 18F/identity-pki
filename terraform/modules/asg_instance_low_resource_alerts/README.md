# Autoscaling Group Low Instance Resource Alarms

This module relies on aggregated metrics provided by the [AWS Cloudwatch Agent](https://github.com/18f/identity-devops/blob/main/kitchen/cookbooks/login_dot_gov/templates/default/amazon-cloudwatch-agent.json.erb) and alerts when any instance in the ASG does not have a minimum of free memory or disk space.
