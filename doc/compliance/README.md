# Suggested documentation compliance workflow

We currently have one [OSCAL profile](./profiles/gitlab/profile.json) that adheres to selected controls in the NIST 800 53 (rev 5, moderate) and GSA CIS Docker Benchmark (v1.2.0) catalogs.

Here is a suggested compliance documentation workflow that uses [compliance-trestle](https://github.com/IBM/compliance-trestle):

- Add a control to the [gitlab profile](./profiles/gitlab/profile.json) that we will satisfy.
- Run `make generate` to have `trestle` generate the corresponding control statement in Markdown.
  - This Markdown file will live in `dist/system-security-plans/gitlab/`.
- Flesh out implementation detail stubs for that control.
  - It is OK to leave a control implementation description blank initially.
  - We will backfill missing implementation descriptions as we go along.
  - If we need to link to existing code, please link to high level artifacts with a general description.
    - Please avoid linking directly to lines of code as these will change over time.
      - For example, please link to the `identity-gitlab` cookbook instead of line 8 of `http-proxy.conf.erb`.
- (Optionally) Run `make assemble` to generate the resulting OSCAL System Security Plan (SSP).
  - This is an optional step because nothing uses the OSCAL SSP yet.

An example may be illustrative.

- I add `ac-2` to the NIST import in the [gitlab profile](./profiles/gitlab/profile.json).
- `make generate` produces [ac-2.md](./dist/system-security-plans/gitlab/ac-2.md)
- I fill out the controls except for subsection `g` which I cannot address at this time.
- I commit and push to the repository and go through the usual code review procedures.
- At some time in the future, I add support for `ac-2:g` and link to the commit introducing that support.
- Rinse and repeat for each control we want to document/expand upon.

## Status

To track compliance status, we have a header yaml file with a status list. The options are:

- `c-not-implemented`: this control has not been met.
- `c-not-documented`: this control has not been documented. 
- `c-implemented`: this control has been met.
- `c-documented`: this control has been documented.
- `c-organization-defined`: this control should be organization defined.
- `c-inherited`: this control is inherited from the login.gov SSP.

`make status` will print out some basic metrics about control status bits.

## Notes

- We are using JSON primarily because `trestle` YAML support is spotty. This may change in the future.
- We do not need a lot of features that `trestle` offers and are currently using a small subset of these features.
  - This workflow is intentionally primitive: for instance, we generate only the control documentation and fill out the implementation details.
  - We do not support profile authoring or editing or adding items in the control statement.
  - This also means that we do not (currently) have plans to actually use the SSP OSCAL file but the SSP is nonetheless is intended to be a final compliance artifact.
- The use of "System Security Plan" here is somewhat of a misnomer but is a byproduct of `compliance-trestle` and its [opinionated directory structure](https://ibm.github.io/compliance-trestle/cli/#opinionated-directory-structure).
- Link checking and general compliance documentation validation via CI pipelines is a possible future improvement.
