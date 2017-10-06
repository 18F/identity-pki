# WAF Setup

We use WAF to perform ingress filtering for traffic hitting the IDP app.  A WAF ACL is a set of rules that can be attached to one or more ALBs or Cloudfront distribution.  These ACLs can be used to block traffic based on origin or content of the request.  In practice, we use rules intended to block common attack vectors, such as apparent cross-site scripting or SQL injection.  We can also use WAF to perform rate limiting.

## WAF and Terraform

Terraform does not presently support WAF for ALBs.

There are two categories of WAF objects in the AWS API.  The first category are regionless "WAF" objects.  These can only be attached to Cloudfront distributions, which was the original use case for WAF.  Terraform has some support for these objects, but the support doesn't appear to be production-ready.  We can't use these "WAF" objects for ALBs, so they are not useful for us.  The second category are "WAF Regional" objects.  These are largely the same as the "WAF" objects, but intended to be attached to region-specific AWS primitives, and ALBs in particular.  Terraform support for "WAF Regional" objects is under active development and is not presently available to us.

## Shared WAF ACLs

Since we cannot configure WAF in Terraform, we instead just create a single shared ACL, and use Terraform's `local-exec` feature to associate an ACL with an environment's ALB.  To set up the ACL from scratch:

1. https://console.aws.amazon.com/waf/home?region=us-west-2#/webacls
2. "Create web ACL"
3. Web ACL name: `shared_idp_web_acl`
4. CloudWatch metric name: `sharedidpwebacl` (it doesn't like underscores)

We started with the set of "common" conditions (https://s3.amazonaws.com/cloudformation-examples/community/common-attacks.json) used in the tutorial at http://docs.aws.amazon.com/waf/latest/developerguide/tutorials-common-attacks.html:

1. Bad IP list (`bad_ip_match`).  This is empty for now but enables us to add IPs to it and have them immediately take effect. Will update this to import known IP reputation via a Lambda function.
2. Size constraint (`size_match`).  Match content size greater than 8192 bytes.
3. SQLi (`sqli_match`).  Set up the following:
  - Query string, HTML unescape
  - Query string, URL unescape
  - Body, HTML unescape
  - Body, URL unescape
  - URI, URL unescape
4. XSS (`xss_match`).  Set up the same set of things as in #3.

When setting up rules, create one rule for *each* of the match conditions you just created.  I named them `bad_ip_rule`, `size_rule`, `sqli_rule`, and `xss_rule`.  Accept the generated CloudWatch metric name for each of these.  We'll need this for alerting.

Finally, add each rule to the ACL, such that each rule blocks requests, and the default for the ACL should allow requests that don't match any rules.
