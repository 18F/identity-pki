# Network ACL Operational Hacks

Using network ACLs in terraform can be pretty miserable.

This file provides some documentation for the `bin/oneoffs/nacl-*` hack files.

They allow us to deploy network ACL changes even though Terraform 0.8 is
incapable of handling several common situations.

**The basic approach:**

1. Add a temporary allow all rule as rule #1
```
nacl-migration.rb add-allow-all NACL_ID
```
2. Delete all network ACL rules except for rule #1 from the network ACL
```
nacl-migration.rb delete-all-rules NACL_ID
```
3. Delete all network ACL rules for the NACL from the TF state file so that
   terraform plan doesn't explode
```
nacl-delete-from-tfstate.sh NACL_ID
```
4. Run terraform plan and terraform apply
5. Remove the temporary allow all rules
```
nacl-migration.rb remove-allow-all NACL_ID
```

**Why is this necessary?**

Terraform is unable to handle several common situations:

- When you use the non-inline `aws_network_acl_rule` resource, it doesn't
  delete unmanaged/unknown rules. (WONTFIX)
- You cannot mix inline and non-inline rule styles. (WONTFIX)
- If a rule exists in the statefile but not actually in AWS, terraform
  explodes. (This one is at least acknowledged as a bug, possibly fixed in 0.9)
- If a rule exists with the same rule number as one that terraform is trying to
  create, it explodes. (WONTFIX)

**Is this secure?**

At time of writing, we don't actually rely on network ACLs for security
anywhere. We rely on security group rules for our actual network protection. So
temporarily allowing all traffic through the network ACLs should not pose any
security concern. Operators should verify that this is still the case when
rolling out changes in this manner.
