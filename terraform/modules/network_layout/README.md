# Network Layout

This module reads a generated map of supernets and subnets usable for
non-overlapping VPC and subnet addressing with IPv4 and IPv6.

It also includes the `update_layout.py` tool to read `network_schema.yml`
and update `network_layout.json`, carving up 100.64.0.0/10 (RFC 6598
Carrier NAT) space into unique networks optimized for simple routing.

Note - Due to initial selection of IPs from 172.16.0.0/12, we were
unable to add secondary blocks from 10.0.0.0/8.
See [IPv4 CIDR block association restrictions](https://docs.aws.amazon.com/vpc/latest/userguide/configure-your-vpc.html#add-cidr-block-restrictions)

Location and metadata are mapped to "slots" which are used
to calculate the addressing for a given VPC or subnet.

This module is for greenfield use should not be used with
existing network schemes.

**Note - `network_layout.json` and `network_schema.yml` files contain
environment specific IP addressing information and should not be
stored in a public source control repository.**

# Configuration

Slots are defined in network_layout.yml

# Location Data

## Regions

A __region__ is the largest division of network resources.  You
may define standard AWS, Azure, GCP, etc. regions as well as
non-cloud provider regions to fit your layout.  For more see:

* [AWS Regions and Availability Zones](https://aws.amazon.com/about-aws/global-infrastructure/regions_az/)
* [Azure Regions and Availability Zones](https://docs.microsoft.com/en-us/azure/availability-zones/az-overview)
* [GCP Geography and Regions](https://cloud.google.com/docs/geography-and-regions)

## Availabity Zones

An AZ or __zone__ (or "datacenter" in old school terminology) represents a
physical failure domain.  While a single zone may be very robust, it will
generally have one or more shared dependencies that could knock it offline.

It is critical to place resources in at least two availability zones to
provide highly available service.

## Environments

An __environment__ represents a complete deployment environment.  It may be
stretched across regions, zones, etc.  The most obvious is currently called
`prod` (though "app-prod" might be a more appropriate name).  Other examples
include `gitlab-production` and `int`.

As a rule of thumb, everything in an environment should exist within the
same [authorization boundary](https://www.fedramp.gov/assets/resources/documents/CSP_A_FedRAMP_Authorization_Boundary_Guidance.pdf)
It may leverage multiple Cloud Service Providers (CSP) underneath.

It is recommended that special "sandbox" environments be used for throwaway/test
environments.  This will utilize overlapping space to prevent eating up
limited space on ephemeral/short lived environments.

## Purposes

A __purpose__ is a shared grouping of the type of thing that lives in a given
subnet.  It is the smallest division.  We are long past the days of hubs,
and microsegmentation tools like [Security Groups](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html)
should provide most node to node traffic policy.

So why still have different subnets for different types of things?

* Administrative - Keeping fully managed services (such as VPC endpoints),
  shared responsibility services (such as Elasticache Redis), and customer
  responsibility instances (EC2 instances or Kubernetes Pods) in separate
  networks ensures easy calculation of available IPs and avoids potential
  conflict or confusion
* Private vs. Public subnets - Most should be private, but some must be public
* Sometimes you need a good old IP based rule - NACLs still exist, and some
  cases do not allow for using a microsegmentation object (security group) as
  a source or destination.

# Background

## Why add space now?

When launched Login.gov used IPs from 172.16.0.0/12 space with overlapping
space used between VPCs.  This simple layout suited the early stages of
Login.gov.

The following developments warrant adding much more space and also having
some non-overlapping space:

* Scale - We need to support thousands of instances (and later Kubernetes Pods)
  While we could use more space in 172.16.0.0/12, it is cramped.
* Multi-Regionality - While we may not initially route between regions,
  having non-overlapping space between regions ensures we can as needed in the
  future.
* Observability - All of our logs now feed into a SOC.  At times it is very
  hard to discern what environment (and thereby, which actual instances) are
  being referred to when only an internal IP is provided.  Non-overlapping space
  for long-lived environments like `prod` speed diagnosis.

## Do we need non-overlapping space?

Maybe not...?  In general, avoiding inter-VPC routing to prevent lateral
movement.  At some point we may need to support inter-VPC routing.

We will have non-overlapping space anyway: IPv6 will not overlap.

There is also an argument to be made for easier troubleshooting and security
response if specific high-value environments have non-overlapping space.

## Why this "auto-layout"?

No one likes laying out networks, particularly cloud-native developers.
This module makes laying out space that supports multiple providers/regions,
environment partitions, availability zones, and types of use.  It prevents
having to maintain a giant spreadsheet or think about avoiding overlap
when planning growth.

## Why 100.64.0.0/10?

The original concept used 10.0.0.0/8 from [RFC 1918](https://www.rfc-editor.org/rfc/rfc1918.txt)
Unfortunately, AWS has [strict rules](https://docs.aws.amazon.com/vpc/latest/userguide/configure-your-vpc.html#add-cidr-block-restrictions)
on adding secondary space.

Carrier NAT space (100.64.0.0/10) provides plenty of room for our needs.  As a fully cloud
hosted service and part of GSA (which has its own /16), it is highly unlikely we ever need
to deal with a remote peered network using carrier NAT.

