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
