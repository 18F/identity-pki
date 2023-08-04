---

# Architecture Decision Record 10: Blessed Images

> We will denote which images are allowed to run on env runners by moving them
> to special "blessed" repos, indicating the images are also "blessed".

__Status__: Implemented

## Context

The current method of updating an allowlist of digests in S3 requires editing
files in mutiple AWS accounts, and restarting runners in multiple production and
lower environments. We've missed parts of this process multiple times:

- https://gsa-tts.slack.com/archives/C023LB27CCQ/p1690556845452309?thread_ts=1690556621.403389&cid=C023LB27CCQ
- https://gsa-tts.slack.com/archives/C023LB27CCQ/p1689872118118329
- https://gsa-tts.slack.com/archives/C023LB27CCQ/p1679070344372429

## Decision

We will simplify by providing a wildcard to the GitLab runners that restricts
the images they run to those we have explicitly blessed. We will manually copy
blessed images to read-only (from GitLab's point of view) ECR repos ending with
"/blessed".


## Consequences

New images can then be used without restarting every runner. At a high-level, the new process is:

1. Verify an image version is safe and appropriate to use.
2. Use the `crane` tool or similar to copy the image to a "/blessed" repo while
   maintaining its digest.
3. Use the `bin/sign_image.sh` tool to sign the resulting image with cosign.
4. Submit and merge a PR with the new digests.

## Alternatives Considered

An alternative method would be to restrict the images runners may use to images we
have cryptographically signed. We have the tooling to sign images, however we do
NOT currently have the ability to preemptively stop the runners from executing
unsigned images.
