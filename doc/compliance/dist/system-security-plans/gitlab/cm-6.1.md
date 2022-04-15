---
status:
  - c-implemented
  - c-documented
effort:
  - medium
---

# cm-6.1 - \[catalog\] Automated Central Management / Application / Verification

## Control Statement

The organization employs automated mechanisms to centrally manage, apply, and verify configuration settings for organization-defined information system components.

## Control Objective

Determine if the organization:

- \[1\] defines information system components for which automated mechanisms are to be employed to:

  - \[a\] centrally manage configuration settings of such components;
  - \[b\] apply configuration settings of such components;
  - \[c\] verify configuration settings of such components;

- \[2\] employs automated mechanisms to:

  - \[a\] centrally manage configuration settings for organization-defined information system components;
  - \[b\] apply configuration settings for organization-defined information system components; and
  - \[c\] verify configuration settings for organization-defined information system components.

______________________________________________________________________

## What is the solution and how is it implemented?

Gitlab is deployed and tested in a fully automated fashion using
AWS CodePipeline and CodeBuild.

______________________________________________________________________
