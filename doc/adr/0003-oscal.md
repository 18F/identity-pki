# Architecture Decision Record: Using OSCAL for compliance authoring

> Use [NIST OSCAL](https://pages.nist.gov/OSCAL/) for authoring compliance documentation.

__Status__: Implemented in [https://github.com/18F/identity-devops/pull/3983][impl]

## Context

Historically, compliance has been one of the biggest challenges for deploying new architecture, and so one of our highest priorities for our hosted Gitlab implementation was to bake in compliance documentation where-ever possible. The long-term vision is figuring out efficient workflows and engaging the compliance team in the process as we build towards compliance-as-code.

## Decision

We will use OSCAL, and in particular an IBM project called [Compliance Trestle](https://github.com/IBM/compliance-trestle), to aid us in writing compliance documentation. We will be using OSCAL lightly, which means we will primarily use OSCAL profiles to generate markdown files for authoring compliance documentation. We will also optionally convert compliance documentation back into an OSCAL System Security Plan (SSP).

## Consequences

Positive consequences of this decision involve a minimal compliance documentation workflow, the use of a compliance standard that is backed by NIST, and the ability to specify which controls, exactly, to meet.

Using OSCAL in our compliance documentation is an experimental approach, and most consequences are unknown as of yet. It may be that the developers find authoring to be overly cumbersome, or perhaps that the compliance team is not willing to validate or examine the resulting compliance documentation.

## Alternatives Considered

We considered using [OpenControl](https://open-control.org/) and [Compliance Masonry](https://github.com/opencontrol/compliance-masonry) but this standard and tool, respectively, are long abandoned and unlikely to see future development.
