# Base NACL Rules

A simple module that attaches NACL rules for the following:

- Egress for package installation
- Ingress/Egress for NTP
- Ingress for ephemeral ports

This is to avoid duplication of a common pattern in our networking.
