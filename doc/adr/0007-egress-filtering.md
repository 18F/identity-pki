# ADR 7: Egress Filtering with Large Autoscaling Groups

> Egress filtering and efficient public IPv4 address use reduction for wider scale.

__Status__: accepted

## Context

Egress filtering is used to prevent processes on servers (instances)
from connecting to anything on the Internet that is not explicitly allowed.
This was originally implemented with our `outboundproxy` hosts which are
Squid HTTPS proxies with DNS name based filtering.  These use the same
home grown and Chef based provisioning as our legacy deployment model.

For egress traffic other than HTTPS, (such as SSH to GitHub), a mix of Security
Group rules and  public subnets were used.  This is not ideal since it leaves
all servers in public subnets, eliminating one of the guardrails that prevents
direct internet access inbound to servers.  It also goes against [FedRAMP Subnet Guidance](https://www.fedramp.gov/assets/resources/documents/FedRAMP_subnets_white_paper.pdf).

For wider scale, better security, and a stronger compliance
stance we must:
* Have a scalable high performance HTTPS egress filtering system
* Stop using public subnets for servers and instead utilize IPv4 NAT

## Decision

We will:
* Implement NAT Gateways for IPv4 address translation
* Bind NAT Gateways to our static EIP pools to maintain the expected source IPs
  as defined in [Runbook: External public static IP addresses](https://github.com/18F/identity-devops/wiki/Runbook:-External-public-static-IP-addresses#egress-ipv4-addresses)
* Modify all subnets with compute instances (EC2 or otherwise) attached to be
  `private` instead of `public`
* Leave Squid proxies in place for now
* Revisit egress filtering as part of application containerization efforts and
  eliminate the full instance Chef based `outboundproxy` systems

## Consequences

* Eliminates issues with limited space in EIP pools, allowing for over 120
  production `outboundproxy` instances
* Maintains the `outboundproxy` egress filtering model that the team is well
  versed in operating and maintaining
* Avoids the rough edges and potential hidden limitations of the Network Firewall service
* Avoids investing limited compliance resources in replacing the high profile egress filtering
  layer


## Alternatives Considered

Significant work was put into developing an AWS Network Firewall solution.
After careful consideration the service was found to be immature in some
respects, missing some Terraform support, and not worth the lift at this time.

See [AWS Network Firewall POC](https://docs.google.com/document/d/1IhCtkMEjYxZC2TQmMF620jTpUF3cZ4oXKgamesVKZ0Y/edit#heading=h.lgconc6ikjp3)
for details.
