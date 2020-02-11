# ELK Stack Operations

The passwords for ELK users are stored in the `login-gov.secrets` bucket of each account.
(e.g. for identitysandbox.gov:)

```
aws s3 cp s3://login-gov.secrets.894947205914-us-west-2/common/elk_htpasswd.json -
```

Since they are stored in the `common` subdirectory, the passwords themselves are
stored account wide.

You can generate a password hash for yourself by running, then add it to the JSON file in S3:

```
htpasswd -nB -C 10 <username>
```

which users are installed in each environment is stored in the per environment
configuration files in `kitchen/environments` in `identity-devops`.  The setup
of the ELK instance will fail if there is no password for a user it's trying to
create.
