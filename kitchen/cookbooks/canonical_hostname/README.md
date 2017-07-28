# canonical_hostname

A cookbook providing helpers for building the "canonical hostname" of an
instance.

The instance is expected to have "prefix" and "domain" tags.  If it does, the
canonical hostname is: `<prefix>-<instance_id>.<domain>`.

If those tags do not exist, this libary falls back on IP address and logs a
warning.
