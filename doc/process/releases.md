# How to release infrastructure changes

## Provisioned AWS Resource Changes (Terraform)

### Versioning

The `VERSION.txt` file at the root of `identity-devops` contains the current
version of the terraform configuration.  Currently this only applies to the
`identity-app` configuration.

### Releasing

Run `rake release` to show usage.  This command will:

- Bump the version in `VERSION.txt`.
- Create a new release commit.
- Create a new git tag.
- Bump the patch version in `VERSION.txt` and tag it as pre release.
- Create a new pre release commit.

Note that this is all local, so it does nothing to manage the process of
actually getting this merged into master.  If you don't have push permissions to
master, you can create a PR, get that merged, and then run `git push --tags`
after you're sure the tags are still correct.

#### Release example

    $ cat VERSION.txt
    0.1.0-pre

    $ rake release[minor]
    + bundle exec rake release[minor]
    Cutting minor release:"0.1.0-pre" -> "0.2.0".
    Cutting "0.2.0" release.
    git add VERSION.txt
    git commit -m "Release version 0.2.0"
    [sverch/feature/deploy-version c4b7d6f] Release version 0.2.0
    1 file changed, 1 insertion(+), 1 deletion(-)
    git tag v0.2.0
    Setting version to "0.2.1-pre" post release.
    git add VERSION.txt
    git commit -m "Post release version 0.2.1-pre"
    sverch/feature/deploy-version 799444d] Post release version 0.2.1-pre
    1 file changed, 1 insertion(+), 1 deletion(-)

    $ git log --pretty=oneline --decorate -3 --abbrev-commit
    799444d (HEAD -> sverch/feature/deploy-version) Post release version 0.2.1-pre
    c4b7d6f (tag: v0.2.0) Release version 0.2.0
    b1e209d (origin/sverch/feature/deploy-version) Make environment version check a warning

    # <after pull request is merged>

    $ git push --tags

### Deploying

To see the currently deployed version for a given environment, run
`bin/get-version-info.sh`.

Check out the next consecutive version.

Use the `deploy` script in `identity-devops` to plan and apply the terraform
changes.

## Server Configuration Changes (Chef)

### Versioning

Each cookbook has its own version, and when releasing a new cookbook you should
bump the version in the cookbook's metadata.

### Releasing

Run the [regression tests](../testing.md) before you bump the version.  Then,
when you want to add this to an environment, update the environment config file
in `kitchen/environments/{env_name}.json`.

### Deploying

The correct cookbook version either gets uploaded to the chef server by
terraform on the first run or by jenkins whenever the tracking branch changes.
See https://github.com/18F/identity-private/issues/1788#issuecomment-300267880.

TODO: Documentation for Jenkins rollout/tracking branch configuration.

Once https://github.com/18F/identity-private/issues/1942 is resolved, the
deployment stage will be part of the Terraform deploy which will eliminate the
need for keeping these in sync using a chef server.

## Application Code Changes (Jenkins)

See:
https://github.com/18F/identity-private/wiki/Operations:--Deploy-Application-Code-with-Jenkins

Also see: https://github.com/18F/identity-private/issues/1709
