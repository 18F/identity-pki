# Login.gov infrastructure architecture

This page describes at a high level the systems that are running in the
login.gov infrastructure, and what they are for.

Refer back to the [Getting Started Guide](../getting-started.md) for more
details on how to work with the infrastructure.

## Postgres (RDS)

RDS is configured entirely by terraform.  There is one RDS cluster for all the
IDP hosts, and another for the app hosts if they are enabled.

After RDS is setup for the first time, the admin password must be changed to
something secret not known by terraform, since terraform stores passwords in its
state file.

## Redis (Elasticache)

Elasticache is configured entirely by terraform.  There is one RDS cluster for
all the IDP hosts, and another for the app instance (which runs the dashboard
and the service provider examples) if it is enabled.

## KMS

We deploy a per environment KMS key.  This can be used by the application to do
encryption and decryption scoped to each environment.

## IDP Servers

The IDP servers are the user facing servers that run the main identity-idp code.
See the [identity-idp](https://github.com/18F/identity-idp) repository for more
details.

## IDP Worker Servers

The IDP Worker servers are the backend job servers that run the workers that
handle sending SMS and email.  See the
[identity-idp](https://github.com/18F/identity-idp) repository for more details.

## ELK Server

This server runs logstash and kibana and connects to our elasticsearch cluster
on the backend.

## Elasticsearch Servers

These servers run elasticsearch and are the backing storage for our ELK stack.
Logs are also sent to S3 by logstash, so this is not the single source of the
log data, but is used by the kibana dashboard.
