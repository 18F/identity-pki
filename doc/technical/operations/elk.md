# ELK Stack Operations

The passwords for ELK users are stored here:

```
aws s3 cp s3://login-gov-secrets-test/common/elk_htpasswd.json -
```

They are stored in the `common` subdirectory so the passwords themselves are
stored account wide.  Note also that the production secrets bucket is currently
`login-gov-secrets`, but this may change.  See [Secrets
Deployment](../deployment/secrets.md) for more details.

You can generate a password hash for yourself by running, then add it to the JSON file in S3:

```
htpasswd -nB -C 10 <username>
```

which users are installed in each environment is stored in the per environment
configuration files in `kitchen/environments` in `identity-devops`.  The setup
of the ELK instance will fail if there is no password for a user it's trying to
create.
