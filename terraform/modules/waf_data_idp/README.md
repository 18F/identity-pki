This is a data module to keep our IdP WAF extensions aligned.

Outputs:

restricted_paths - Map with subkeys of:
  - paths - List of regexes matching paths that should be restricted to
            specific IP address ranges.
  - exclusions - List of regexes for paths (matched in "paths") that should
                 be allowed from anywhere.

privileged_cidrs_v4 - Sorted list of IPv4 CIDR blocks allowed to access the restricted
                      paths.

privileged_cidrs_v6 - Sorted list of IPv6 CIDR blocks allowed to access the restricted
                      paths.


