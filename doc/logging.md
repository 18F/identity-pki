# Login.gov Logging

## ELK

We currently deploy an [elk server and two elasticsearch
nodes](https://github.com/18F/identity-devops/blob/d27063db9d5c512e88d70f1e61a8ac47bc713f30/app/elk.tf).

The configuration for this server can be found
[here](https://github.com/18F/identity-devops/tree/d27063db9d5c512e88d70f1e61a8ac47bc713f30/kitchen/cookbooks/identity-elk/templates/default).
For example, we currently output logs to
[s3](https://github.com/18F/identity-devops/blob/d27063db9d5c512e88d70f1e61a8ac47bc713f30/kitchen/cookbooks/identity-elk/templates/default/30-s3output.conf.erb).

