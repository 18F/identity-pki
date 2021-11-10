
# Architecture Decision Record: Establish Format for ADRs

> Start documenting infrastructure architecture decisions.

__Status__: Implemented in [][impl]

#### Context

We want to have records of architectural decisions, especially on Team Mary as we build out a new release pipeline. 

#### Decision

Document team decisions through ADRs, and use git to track them so they can be reviewed by the team prior to acceptence.

#### Consequences

For any architectural decision made, there is now a new acception criteria that it be accompanied by a record. You can find the template for ADRs [here](./xxxx-template.md).

#### Alternatives Considered

We considered using the [wiki](https://github.com/18F/identity-devops/wiki) but opted for `doc/adr` instead for two reasons: 1. So a review is required by the team for acceptance into the record and 2. We can keep record in individual markdown files for easy reference.

[impl]: 