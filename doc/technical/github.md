# Github Repository Notes


## Machine access to private repos

We have a a number of private github repos that must be cloned by Login.gov servers as part of bootstrapping.

There are two patterns that we use to facilitate this.

### [`identity-servers`](https://github.com/identity-servers) github user (preferred)

The new preferred mechanism for cloning private repositories is to use the special Github user that we have created for this purpose, [`identity-servers`](https://github.com/identity-servers). This user is given read-only permissions to various repos by being a member of the [identity-bots-ro](https://github.com/orgs/18F/teams/identity-bots-ro) team.

#### login credentials

The password and MFA details to log in to identity-servers are stored in the prod AWS account in AWS Secrets Manager under `devops/github/identity-servers/*`.

These credentials are not especially sensitive so long as the data that `identity-servers` can access is not sensitive. (Which it shouldn't be since we don't store any sensitive data in Github, and `identity-servers` has read-only access.)

The org permissions force us to have MFA enabled, but since the password is a long random one we don't really care about MFA.

Devops team members should feel free to add their personal U2F security keys to the `identity-servers` account to facilitate access.

### per-repo deploy keys (deprecated)

Before we had the `identity-servers` github user, we created deploy keys on each private repository that we wanted to clone. This is a nuisance if you have many repositories, because given _N_ repos you have to juggle _N_ SSH keys. The `id-git` script is used on servers to make this slightly less painful.

Currently these repos are cloned using per-repo deploy keys:

- identity-devops
- identity-devops-private

We should migrate the bootstrapping process to use the `identity-servers` user for everything, and then revoke all the per-repo deploy keys.


### SSH key storage / delivery

At the moment, all of the SSH public and private keys are stored in S3 in the secrets bucket under the `common/` directory.

For example:

- `common/id_ecdsa.id-do-private.deploy` — for identity-devops-private
- `common/id_ecdsa.identity-devops.deploy` — for identity-devops
- `common/id_ecdsa.identity-servers` — for the identity-servers user

At some point these should probably be moved to AWS Secrets Manager. But the storage of these keys is not security-critical because they grant only read access to private-but-not-secret repositories.

If we ever gave any of these credentials the ability to access truly secret data, then the security of the keys would become correspondingly more important. If that occurred, we would also probably want to start rotating the keys periodically. Currently rotation is not necessary since the keys only grant access to private repos containing only non-secret data.

