This is initially our "payer" account.  Only the base logging and inbound
Analytics role access are enabled at this time.

In the future we may enable full org privileges here.  To prevent polluting the
account only members of the `orgadmin` group in `login-master` will be allowed
to assume the FullAdministrator role in this account.  This role requires scoping
down before we enable full management functionality.

Root is held by our reseller, 4points.  They have IAM users under this account.
In case of emergency they can help regain access.


