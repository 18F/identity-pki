# Architecture Decision Record: Using Login.gov as Primary Gitlab Auth

> Use Login for authenticating users on our CI/CD tooling.

__Status__: Implemented in [][impl]

#### Context

We needed authentication for the new release pipeline on our hosted Gitlab. The categories of criteria for which system to use were security, user experience, compliance, and operator experience.

#### Decision

We will use login.gov to authenticate users to our hosted Gitlab. In addition to login.gov as the primary auth system, we will provide a secondary fallback, as well as an administrator breakglass solution.

#### Consequences

Positive consequences of this decision include a great developer and operator experience, use of a FedRAMP Moderate tool, less time spent learning how to integrate with an unknown toolset, and a clear separation of authentication and authorization.

There is a security implication that if the secure.login.gov is compromized, it would be possible to gain control of the control plane. However, an incident like this would imply a secondary control plane had already been established by an advesary, and the threat to the existing control plane would pose no further threat than the existing one. Furthermore, by using our own tools we have a heightened awareness of the security of the platform. We build expertise on the operating team in the product. This process is called 

There is also an availability consequence – how do we get secure.login.gov back online if the release pipeline for it is also inaccessible? This is the motivation for designing administrator breakglass and secondary fallbacks into the system from the start. Even if our secondary authentication is inaccessible, it is always possible for an administrator to access Gitlab to initiate builds and deployments of patches for the system.

#### Alternatives Considered

Primary alternatives considered were SecureAuth or a PIV proxy TKTK.

[impl]: 