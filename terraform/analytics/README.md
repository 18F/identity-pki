## terraform-analytics

These scripts set up redshift and a lambda function for the analytics pipeline,
This infrastructure is deployed inside of its own VPC and should have zero impact
on the rest of login.gov infrastructure. This module's only contact with the
rest of login.gov ecosystem is by way of the s3 logs buckets prefixed: `s3://login-gov-${env}-logs`

## Deployment

From the root of `identity-devops` run:

```
./deploy-analytics <env_name> plan
```

Where <env_name> is the name of an existing environment you want to attach
analytics to.  Then to apply the changes, run:

```
./deploy-analytics <env_name> apply
```

The lambda functions can be found in `s3://tf-redshift-bucket-${env}-deployments`
Please specify the latest function version for your environment as the analytics version.
The Redshift Master Password can be found in `s3://login-gov-${env}-redshift-secrets/redshift_secrets.yml`
for the respective environment you are deploying in. Please only deploy in `us-west-2`
for the time being.
