# Base AMI

We need to deploy an an AMI that is FISMA compliant.  We have a way we do this
now, but it's based on a repo we don't have access to and that only some members
of the team can use.  See
https://github.com/18F/identity-devops-private/issues/39 for discussion.

The current AMIs we use should all be in `identity-devops-private`.  As of this
writing, the default base AMI we use is `ami-7e22c506`, as you can see here:
https://github.com/18F/identity-devops-private/blob/e3be89277d76ecfa0eea554524926860e6f41b40/env/base.sh#L41.
