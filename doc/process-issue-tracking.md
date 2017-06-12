# Process: Issue Tracking, Repo Layout

The login.gov infrastructure is primarily developed in this repository,
[identity-devops](https://github.com/18F/identity-devops). Although it is
currently private, our intent is to make it open source and to do development
more in the open.

The objective is for a team anywhere in the world to be able to stand up the
full login.gov infrastructure.

But some of the project's work benefits from being kept private. In addition to
the public, open source IDP repo
[identity-idp](https://github.com/18F/identity-idp), the team uses a central
private repo [identity-private](https://github.com/18F/identity-private) for
tracking private issues and goals, keeping private documentation, and generally
having a place for private but not secret data.

This repository became cluttered with multiple login.gov teams' work, making it
hard to get a concise view across a single team. The login.gov DevOps team
moved our private issue tracking to a separate private repo:
[identity-devops-private](https://github.com/18F/identity-devops-private).

We use the
[identity-devops-private](https://github.com/18F/identity-devops-private) repo
to track internal private communications, issues, project status, and
configuration that we prefer not to make public.

The vision in the longer term is that any organization wishing to stand up an
instance of login.gov would keep a private configuration repo like this for
their private, environment-specific variables. The private repo should be kept
as small as possible, so it only contains private configuration parameters
specific to a particular login.gov installation, not scripts or automation
necessary to run all installations. See also
https://github.com/18F/identity-devops-private/issues/1 which describes the
rationale in greater detail.

For moving GitHub issues between repositories, we used a oneoff script:
[/bin/oneoffs/github-copy-issues.rb](../bin/oneoffs/github-copy-issues.rb)

## Environment variable configuration

The deploy scripts (`deploy`, `bootstrap.sh`) use environment variables to pass
a number of configuration parameters to terraform. An environment variable
named `TF_VAR_foo` will be treated by Terraform as variable `foo`.

This allows us to specify configuration values that are specific to our
deployment of the login.gov infrastructure, such as account ID, AWS region, AMI
IDs, etc.

Some of these values may differ between environments. The `bin/load-env.sh`
script loads values from identity-devops-private. It will load an
environment-specific file (e.g. `dev.sh`) if one exists for the current
environment. This file will itself typically source `base.sh` to get common
settings. If no file exists for this environment, then `load-env.sh` will load
`default.sh` instead.

Certain values may differ permanently, for example the `TF_VAR_account_id`
because there may be separate AWS accounts for production and testing.

Other values may differ only temporarily, for example while rolling out a new
version of an AMI or upgrading between versions of Postgres. Our proposed (yet
to be tested in practice) workflow is to issue pull requests and merge as the
changes are rolled out to individual environments or sets of environments.

See the env directory in identity-devops-private for more details:
https://github.com/18F/identity-devops-private/tree/master/env

### Breaking environment changes

Sometimes it's useful to enforce that users are running a recent enough version
of the environment configuration. Because we have decoupled `identity-devops`
from `identity-devops-private`, these versions can change independently. The
`deploy` script will run a `git pull --ff-only` in `identity-devops-private` to
try to get the latest version.

The `bin/load-env.sh` script uses the environment variable
`ID_ENV_COMPAT_VERSION` as a sentinel for the compatibility version. If the
value of this variable is less than the `ENFORCED_ENV_COMPAT_VERSION` set in
`bin/load-env.sh`, it will error out. So if you need to make a breaking change
to the environment scripts and enforce that users are running with a newer
environment, increment `ID_ENV_COMPAT_VERSION` in the environment files in
`identity-devops-private` and increment `ENFORCED_ENV_COMPAT_VERSION` in
`bin/load-env.sh` to require it.

### Long term future of this configuration

In the future, our use of environment variables will ideally be supplanted by
the use of terraform `.tfvars` files and terraform modules. Instead of sourcing
Bash scripts with shell variables, we will put variables in `.tfvars` files
that are specific to each environment. Eventually we plan to make the
`identity-devops` Terraform configuration a module, so then each environment
would get a `main.tf` in identity-devops-private hat references the module with
any necessary parameters.


