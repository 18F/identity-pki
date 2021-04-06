# Network Layout

This module reads a generated map of supernets and subnets usable for
non-overlapping VPC and subnet addressing with IPv4 and IPv6.

It also includes the `update_layout.py` tool to read `network_schema.yml`
and update `network_layout.json`. carving up 10.0.0.0/8 space into unique
networks optimized for simple routing.

Location and metadata are mapped to "slots" which are used
to calculate the addressing for a given VPC or subnet.

This module is for greenfield use should not be used with
exising network schemes.

**Note - `network_layout.json` and `network_schema.yml` files contain
environment specific IP addressing information and should not be
stored in a public source control repository.**

# Configuration

Slots are defined in network_layout.yml

# Location Data

## Regions

A region is the largest division of network resources.  You
may define standard AWS, Azure, GCP, etc. regions as well as
non-cloud provider regions to fit your layout.

## Availabity Zones

## Environments

## Purposes

