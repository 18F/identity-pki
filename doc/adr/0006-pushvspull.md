# Architecture Decision Record 6: Push vs. Pull deployment architecture

> Whenever possible, login.gov should decentralize the power to change environments
> by using a pull model for managing changes.

__Status__: proposed

## Context
Software and infrastructure changes need to be automated as much as possible.  This
automation needs to be applied to both development and production systems.  There are
many CI/CD systems which can do this, but they tend to either subscribe a a push or
a pull model.

A push model deployment system is one where a centralized CD system is granted
credentials/powers to be able to control all of the environments, possibly with
administrative controls within the system to prevent who can push changes to what
environment. Many traditional CI/CD systems are implemented like this by default,
such as Jenkins, Spinnaker, and GitLab.

A pull model deployment system is one where there is no central system that has
credentials/powers, but instead each environment has an CD agent in it which pulls
code down when it changes and has the power to change only its own environment.
[GitOps](https://www.gitops.tech/#what-is-gitops) is an approach which implements
this,and FluxCD and ArgoCD are examples of pull-based CD.

Login.gov has very high security requirements.  As security-sensitive people, when
we look at push-based CD systems, we see a system with a very large attack surface
and a tremendous amount of power and access.  This is a tempting target for attackers,
because it has many users and features which can be compromised to use to attack
GitLab and use it to lateral into our production environment using its many powers.

Pull-based systems are much more secure because the agent empowered to make
the changes is small and not exposed to users.  Each agent is only empowered
to change its own environment, and thus has a smaller blast radius if anything
goes wrong.  However, most traditional CD
systems are not engineered with this deployment method in mind, and thus many
of their CD features don't really apply very well, and it may take extra
engineering work on our part to implement.

## Decision
Whenever possible, login.gov will decentralize the power to change environments
by using a distributed pull model instead of a centralized push model for
deployment.

Some thoughts about why this is a good approach can be
[found here](https://alex.kaskaso.li/post/pull-based-pipelines).

## Consequences
* We will probably have to do some clever engineering to make GitLab support
  pull-based deployments.
* We will have a much more secure and auditable deployment system.
* We may not be able to use some of GitLab's clever terraform and k8s features.
* We will be well-positioned to move to a fully declarative gitops-based system for EKS.


## Alternatives Considered
Just running GitLab with all the privs would be really easy to do.  But as
we say above, it is also very scary, since it has a ton of moving parts and
cool features, any one of which might be exploitable, and thus grant any one
of the many users we expect to be on the system to be able to use all of its
creds.  That said, we sure would love it if our GitLab TAM was able to find
a nice safe way to mitigate these concerns.  We have yet to hear any good
solutions from them on this.

GitLab runners might be an interesting way to fix this, by empowering only those
runners with the IAM privs that they need to manage their env.  But this just
moves the problem one step out.  If you compromise GitLab, you can dispatch
arbitrary jobs to those runners.  There needs to be some way to make it so that
gitlab is unable to execute arbitrary jobs on these runners for this approach
to be safe.

You might say that Git is also just a remote control system like the runners,
but its actually a system that is really good at keeping track of changes.
Combine that with signed commits, and you can ensure that changes to it are
well documented and verifiable, unlike runners who have no good way to verify
that the commands that they are being given are authorized, and there may not
even be a good record of what was done.
