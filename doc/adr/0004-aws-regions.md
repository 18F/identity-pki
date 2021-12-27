# Architecture Decision Record: AWS Region Use For Login.gov

> Use US-West-2 (Oregon) as our primary region and US-East-2 (Ohio) as our alternate/disaster recovery region.

__Status__: proposed

## Context

Since launch, Login.gov has primarily used US-West-2 (Oregon) to host resources.  This was based in
part on it being the only [Renewable Energy Credit/Guarantee of Origin region](https://sustainability.aboutamazon.com/environment/the-cloud) in US Commercial.

As we move toward multi-region recoverability we must select our disaster recovery/alternate region.
The alternate region should not also be on the West coast, precluding use of US-West-1 (Northern California).
That leaves US-East-1 (Virginia) and US-East-2 (Ohio) as candidates.

US-East-1 is a single point of control failure for many AWS services, including [Route53](https://www.lastweekinaws.com/blog/lessons-in-trust-from-us-east-1/).
US-East-1's size and heavy use make it the most likely region to have growth and usage related outages
as it scales.
Treating US-East-1 as a ["Control Plane"](https://en.wikipedia.org/wiki/Control_plane) component reduces
the chance of being unable to migrate services due to same-region dependency.

The remaining region, US-East-2 (Ohio) is well inland, geologically stable, and sufficiently
sized to meet our full production needs.

For more on regions, see [AWS Global Infrastructure - Regions](https://aws.amazon.com/about-aws/global-infrastructure/regions_az/?p=ngi&loc=2).

## Decision

_We will use **US-West-2** as our **primary** region and **US-East-2** as our **alternate/disaster recovery** region._

Exceptions:
* Global / other resources requiring creation in US-East-1
* `login-sms-prod` and `login-sms-sandbox` resources already provisioned in US-East-1

This decision will be revisited upon moving any/all services into the GovCloud partition.

## Consequences

* Data replication for RDS will use **US-East-2** as a target
* Multi-Region KMS keys will only be provisioned in **US-West-2** and **US-East-2**
* DR testing will be conducted using **US-East-2** as a target

## Alternatives Considered

US-West-1 was considered but rejected due to the significant number of natural and 
man made disaster risks shared with US-West-2.

US-East-1 was considered but rejected due to its role as a sort of "super region"
for AWS, as well as its historic performance.

