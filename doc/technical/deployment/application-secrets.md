# Application Secrets

If you are trying to change infrastructure secrets, or are working on a version
of the infrastructure from before application secrets were decoupled from
infrastructure secrets, see [Infrastructure Secrets](infrastructure-secrets.md).

## Changing Secrets

The DevOps team does not manage application secrets, but provides an encrypted
S3 bucket that is protected per environment to allow for secure storage and
download of application secrets.  Application instances will automatically have
permission to access their environment subdirectory in this bucket via an IAM
instance profile.

The name of this bucket is `login-gov.app-secrets.#{account_id}-#{region}`.

You can use the AWS CLI to work with this bucket, but you may need to pass
`--sse aws:kms` since we do server side encryption.  Here are some examples,
using the `application.yml` and `database.yml` that identity-idp expects to
see.

```
# list secrets
aws s3 ls s3://login-gov.app-secrets.555555555555-us-west-2/qa/idp/v1/
2017-09-22 17:25:36       4851 application.yml
2017-09-22 17:25:27        453 database.yml

# download an individual secret file
aws s3 cp s3://login-gov.app-secrets.555555555555-us-west-2/qa/idp/v1/database.yml -

# upload a secrets file
aws s3 cp --sse aws:kms ./application.yml s3://login-gov.app-secrets.555555555555-us-west-2/qa/idp/v1/
```

## Deploying Secrets Changes

Upload the secrets to the [CI Environment](../testing/ci-vpc.md) and then run
the [Integration Tests](../testing/application.md).

To get a deployed application to pick up the secrets changes, you must [Recycle
The Instances](recycling-instances.md).
