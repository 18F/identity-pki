# Login.gov infrastructure architecture

This page documents the base systems that are available in the login.gov
infrastructure.

## Postgres (RDS)

RDS is configured entirely by terraform.  There is one RDS cluster for all the
IDP hosts, and another for the app hosts if they are enabled.

After RDS is setup for the first time, the admin password must be changed to
something secret not known by terraform, since terraform stores passwords in its
state file.

See the [getting started guide](getting-started.md) for more details.

## Redis (Elasticache)

Elasticache is configured entirely by terraform.  There is one RDS cluster for
all the IDP hosts, and another for the app instance (which runs the dashboard
and the service provider examples) if it is enabled.

See the [getting started guide](getting-started.md) for more details.

## KMS

We deploy a per environment KMS key.  This is also configured entirely by
terraform.  See the [getting started guide](getting-started.md) for more
details.

## IDP Servers

The IDP servers are AWS instances that run the main identity-idp code.

See the [instance deployment](instance-deployment.md) documentation for more
details.

## IDP Worker Servers

The IDP Worker servers are AWS instances that run the workers that handle
sending SMS and email.

See the [instance deployment](instance-deployment.md) documentation for more
details.

## Jenkins Server

The jenkins server should automatically deploy new versions of the app, chef,
and terraform.

See the [instance deployment](instance-deployment.md) documentation for more
details.  What Jenkins does is different depending on the deployment method, so
that's important context.

## Chef Server

The Chef Server was used by terraform to provision instances, but is not
used in the auto scaled nodes.  These nodes instead use cloud init to do the
bootstrap and run chef-client in local mode.

See the [instance deployment](instance-deployment.md) documentation for more
details.

## ELK Server

This server runs logstash and kibana and connects to our elasticsearch cluster
on the backend.

See the [instance deployment](instance-deployment.md) documentation for more
details.

## Elasticsearch Servers

These servers run elasticsearch and are the backing storage for our ELK stack.
Logs are also sent to S3 by logstash, so this is not the single source of the
log data, but is used by the kibana dashboard.

See the [instance deployment](instance-deployment.md) documentation for more
details.
