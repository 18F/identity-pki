# Login.gov Logging

## ELK

We currently deploy an [elk server and two elasticsearch
nodes](https://github.com/18F/identity-devops/blob/d27063db9d5c512e88d70f1e61a8ac47bc713f30/terraform-app/elk.tf).

The configuration for this server can be found
[here](https://github.com/18F/identity-devops/tree/d27063db9d5c512e88d70f1e61a8ac47bc713f30/kitchen/cookbooks/identity-elk/templates/default).
For example, we currently output logs to
[s3](https://github.com/18F/identity-devops/blob/d27063db9d5c512e88d70f1e61a8ac47bc713f30/kitchen/cookbooks/identity-elk/templates/default/30-s3output.conf.erb).

## Analytics

We currently have some [ETL Scripts](https://github.com/18F/identity-redshift)
that takes the raw log data from s3 and imports it into Redshift for analytics.

To see the status of this, check in
[here](https://github.com/18F/identity-private/issues/1601).
