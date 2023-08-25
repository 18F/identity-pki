---

# Architecture Decision Record 11: Lifecycle Policy for ECR

> We will only keep the 10 most recent images in any ECR repository.

__Status__: Implemented

## Context

The number of images in our ECR repos continues to grow, leading to:

- Old images with newly-discovered vulnerabilties
- Unnecessary storage costs

Although AWS ECR does not expose the last time an image was pulled, it does
expose when the image was pushed, and can expire old images by count or time.

## Decision

We will add an ECR Lifecycle Policy to every ECR repository to expire all but
the 10 most recent images.

## Consequences

Care must be taken not to push unneeded images to the repos, especially the
blessed repos, as that may cause in-use images to expire.

## Alternatives Considered

All alternatives we considered violate one of the following principles:

- No new image should be used in production without an approved PR.
- No in-use image should be allowed to expire.
- Automation may not promote an image to production.

### Tag in-use images as part of the image-promotion process, and exclude tagged images from expiration.

This adds extra complication, while not solving the following: Assuming a
lifecycle policy that keeps 3 images,

1. DigestA is in use
1. DigestB is pushed, tagging DigestA with "in-use"
1. DigestC is pushed, (retagging DigestA with "in-use")
1. DigestD is pushed, (retagging DigestA with "in-use")
1. DigestE is pushed, (retagging DigestA with "in-use")
1. DigestB is the 4th-newest image and expires. ECR deletes it
1. PR with DigestB is merged
1. DigestB should be in use, but doesn't exist. DigestA still has the "in-use" tag.
1. CI breaks


### Use sinceImagePushed instead of imageCountMoreThan.

The issue with time-based expiration is the scenario:

1. DigestA is pushed, tagged with ":latest"
1. PR with DigestA is merged. All is happy.
1. DigestB is pushed, tagged with ":latest"
1. PR with DigestB is not merged.
1. DigestA expires, but CI still references it.


### Use ":latest" image from a repo.

While this ensures the image always exists, it allows one operator to push and
use a new image without an approved PR.
