# Architecture Decision Record 17: Application Secrets Management

> Move sensitive application configuration to AWS Secrets Manager.

__Status__: Implemented in [!4678](https://gitlab.login.gov/lg/identity-devops/-/merge_requests/4678)

## Context

Application configuration and secrets management within Login.gov is somewhat custom and based on various sources. It includes, but is not limited to:

- Platform/infrastructure-based sources like system environment variables and files in the file system outside of the application repository
- YAML files in application repositories and S3 buckets
- The IDP has "AppArtifacts" and large files like the pwned password database as individual objects in S3

The IDP, Dashboard and PKI applications all use the internally maintained `identity-hostdata` gem which supports the bulk of configuration across the applications. The gem allows defining expected configuration as well as the type for each value (`string`, `integer`, etc.) and relies on two YAML files. The first lives in the application repository as `application.yml.default`, defines the defaults, and does not contain any sensitive information. It is maintained as part of the repository. For deployed environments, the second file lives in S3 in the `app-secrets` bucket, with individual `application.yml` files for each application and environment. This file overrides the defaults.

The structure means that a given application stores all secrets in one blob, and operators edit this file directly. The secrets are all decrypted at once and displayed in plain text when editing the file every time, even if the operator is updating a less sensitive feature flag. This system is simple, but has flaws. The large downsides to it are:

- Secret or sensitive values are comingled with less sensitive configuration values.
- Access control cannot be done at the individual secret level.
- Auditing is difficult as logs will only be able to show an individual person viewed or made an update to the entire file. Diffing S3 object versions can be done to see who made a given edit, but it is cumbersome to do at larger scales.

Two incidents in late 2023 prompted a discussion on how to improve this system:

- [2023-09-25 AAMVA Credentials Published](https://docs.google.com/document/d/1QzrpcucE84dDkd-E6oul1BzAtcf2a3Ie57TIJJABb-8/edit)
- [2023-09-27 AAMVA, LexisNexis Credentials leaked in source code](https://docs.google.com/document/d/1sPBtALyXUEu7qqwRMXvWvBWPROHzEFyX4ClJG4EqUX4/edit)

While there is and has been widespread agreement that the system needs improvement, consensus has been difficult and change has been slow. No significant mitigations or improvments have been implented since then. Secrets Manager usage was reviewed as a Significant Change Request (SCR) [here](https://drive.google.com/file/d/111rMbpGJSPIPBpc2u0mIy9Kb3s7XgNEZ/view).

## Decision

To address the significant flaws in the existing secrets and configuration management, we will move all sensitive secrets in the application S3 YAML files to AWS Secrets Manager. This decision is intended to implement a meaningful step forward, evaluate Secrets Manager, and put us in a place to make further improvements. Similar to the existing S3 buckets, Infrastructure/Security teams will primarily manage the creation and access control for secrets, and Application teams will primarily be responsible for managing the values held in the secrets.

There are other elements of the platform and applications that hold secrets that may also be candidates for using Secrets Manager, but they are a lower priority and may be evaluated in the future.

## Consequences

Much of the consideration and discussion here is based on our current EC2 platform. Some assumptions will not hold for the future platform on Elastic Kubernetes Service (EKS) and may require re-evaluation.

It will allow us to address some of the major flaws in the existing system by:

- Not displaying plaintext secrets when making configuration updates
- Increasing detail and scalability in auditing secret access and modification
- Reducing the number of roles and individuals with access to viewing and modifying secrets

This is not without downsides. It will:

- Make reading or updating secret values more cumbersome
- Increase complexity in configuration management
- Be yet another source of configuration values

## Alternatives Considered

One alternative considered was to separate secrets from configuration in a new S3 bucket or objects. This would allow finer-grained access control and auditing at the same level if we created a new S3 object for each secret. The downside to this approach is it would require a similar amount of effort without the upside of Secret Manager's support for rotation and built-in integration with other AWS services for consuming secrets. S3 also has the potential for more permissive access.

Parameter Store is a second alternative that could be implemented similarly to Secrets Manager, but it lacks native support for rotation and cross-region replication. Parameter Store also has a smaller size limit (4 or 8 KB vs. Secret Manager's 64 KB), though we are unlikely to have an issue with it at this point.

Another alternative is storing the value of the secrets in S3 that would be decrypted by the application when needed is a potential alternative, but is more difficult both operationally and technically. It would require operators to receive the plaintext secret, encrypt it with AWS Key Management Service (KMS), and then put the encrypted value in the YAML file in S3. `identity-hostdata` and applications would have to be updated to accommodate this as well.

As an illustration of what the existing S3 file would look like under this alternative, see:

```yaml
# before
database_password: 'secret_password123'
# after
database_password: '136d7c9e37d04ef23b02255360885ba7'
```

[Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) and [Secrets OPerationS (SOPS)](https://github.com/mozilla/sops) were also considered. They present an attractive alternative by encrypting secrets with something like AWS KMS and storing the result in a more easily accessible storage (git repository, S3, etc.). Sealed Secrets doesn't appear to support encryption with KMS and wouldn't be compatible with the current system. SOPS would be a more significant lift to implement for both the infrastructure and application. Auditing and access control would likely need to be handled primarily at the KMS operations level. Storing the encrypted secrets in a location with wider access brings different risks, including the potential for easier exfiltration for offline attacks.
