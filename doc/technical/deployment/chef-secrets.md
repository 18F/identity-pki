# Chef Secrets

## Changing Secrets

All our secrets are stored in S3 and encrypted using KMS the secrets are
downloaded when chef is run using Citadel.

The bucket that is used is configured as the `citadel.bucket` chef attribute.
For example, as of this writing, [the default is
`login-gov-secrets-test`](https://github.com/18F/identity-devops/blob/cfd89eafd74185ec827fccabca752bbe83c85256/kitchen/cookbooks/config_loader/attributes/default.rb#L1),
and the `prod` environment is configured to use
[`login-gov-secrets`](https://github.com/18F/identity-devops/blob/cfd89eafd74185ec827fccabca752bbe83c85256/kitchen/environments/prod.json#L78).

You can use the AWS CLI to work with these secrets, but you may need to pass
`--sse aws:kms` since we do server side encryption.  Here are some examples:

```
# view a secret in S3
aws s3 cp --sse aws:kms s3://login-gov-secrets-test/qa/equifax_wsdl - ; echo
# copy a secret from qa to dev
aws s3 cp --sse aws:kms s3://login-gov-secrets-test/{qa,dev}/equifax_wsdl
# list secrets in the qa env
aws s3 ls s3://login-gov-secrets-test/qa/
```

## Deploying Secrets Changes

To get the application to pick up the secrets changes, you must [Recycle The
Instances](recycling-instances.md).
