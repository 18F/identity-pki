# Suggested documentation compliance workflow

We currently have one [OSCAL profile](./profiles/gitlab/profile.json) for Gitlab that adheres to selected controls in the NIST 800 53 (mostly rev 4 moderate) and GSA CIS Docker Benchmark (v1.2.0) catalogs.

Here is a suggested compliance documentation workflow that uses [compliance-trestle](https://github.com/IBM/compliance-trestle):

- Add a control to the [Gitlab profile](./profiles/gitlab/profile.json) that we will satisfy.
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

- I add `ac-2` to the NIST import in the [Gitlab profile](./profiles/gitlab/profile.json).
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
- `c-inherited`: this control is inherited from the login.gov SSP or from AWS. ([example](./dist/system-security-plans/gitlab/sr-10.md))

`make status` will print out some basic metrics about control status bits.

## Effort

Some controls are tagged with an `effort` that estimates its level of difficulty. If absent, the `effort` is by default `low`. (Options are `low`, `medium`, and `high`.)

## Parameters

A few controls require us to supply parameters to the control. These parameter choices are given in the official NIST catalog description. For instance, `sc-12.2` requires us to choose between `NIST FIPS-compliant` or `NSA-approved` symmetric keys.

To provide a parameter, edit the [Gitlab profile](./profiles/gitlab/profile.json) and add the relevant parameter id to the `set-parameters` section, along with the value(s) that we think best fits the control. (Note that some controls allow more than one parameter.)

For convenience, all Gitlab controls that require such parameters have the relevant parameter ids documented in its `needs-params` YAML header. If no parameter is given in the profile, the default wording is "No value found". See [sc-12.2](./dist/system-security-plans/gitlab/sc-12.2.md) for an example of both "No value found" and its required parameter list.

It is also possible to override the default parameters for a control if needed.

Once new parameters are set in the profile, please run `make generate` to re-generate the control Markdown with the new parameters.

## Notes

- We are using JSON primarily because `trestle` YAML support is spotty. This may change in the future.
- We do not need a lot of features that `trestle` offers and are currently using a small subset of these features.
  - This workflow is intentionally primitive: for instance, we generate only the control documentation and fill out the implementation details.
  - We do not support profile authoring or editing or adding items in the control statement.
  - This also means that we do not (currently) have plans to actually use the SSP OSCAL file but the SSP is nonetheless is intended to be a final compliance artifact.
- The use of "System Security Plan" here is somewhat of a misnomer but is a byproduct of `compliance-trestle` and its [opinionated directory structure](https://ibm.github.io/compliance-trestle/cli/#opinionated-directory-structure).
- Link checking and general compliance documentation validation via CI pipelines is a possible future improvement.

## Control Families Guide

There are families of controls defined by their prefix (i.e. `ul-`), which groups the controls. Here is a guide for helping which of our *17 control families* you might want to write to. [`control_freak`](https://controlfreak.risk-redux.io/families/) is another great resource for learning more about these families, but note that it is specific to rev. 5, lacks the rev. 4 appendix J, and doesn't include GSA container-related controls. 

### `ac-`: Access Control

This family deals with account management, various levels of access to hardware and software, and access related notifications.

### `ar-`, `ra-`, `tr-`, and `ul`: Privacy Impact and Risk Assessment, Privacy Notice, and Infromation Sharing with Third Parties

These families contain controls around threat modeling, privacy impact, and vulnerability scanning. `ar` was the family name under rev. 4, and `ra` is the name under rev. 5, but these should be examined together when making changes that impact privacy or help reduce risk. 

`tr-` is part of rev. 4 appendix J. It is a "Privacy Notice" that covers much of the same items in `ar` and `ra` but deals with timely notice to the public. `ul` is also part of Appendix J and deals with disclossure of information sharing to third parties. 

### `au-`: Audit and Accountability

These controls will deal with anything around logging for events, record keeping, and formatting of logs.

### `ca-`: Assessment, Authorization, and Monitoring

A little meta, but this family deals with how we actively document security and compliance, where we keep POAMs, how we conduct pen testing, etc.

### `cm-`: Configuration Management

This family documents how we restrict softare usage, where we store configuration, and adhere to "law of least functionality" throughout our system. 

### `cp-`: Contingency Planning

This deals with how we handle our backups, disaster recovery, fallbacks, and any other sort of emergency planning. 

### `di-` and `dm-`: Data Quality, Data Management

There is only one control for `di` and it broadly deals with handling of PII at the organization level. 

Renamed "program management" under rev. 5, `dm` covers how the organization manages user data and PII in both production and testing. 

### `ia-`: Identification and Authentication

This family deals with restricting access to parts or whole of the system. You will find controls relating to MFA, account access, PIVs to access, etc. Unlike `ac-` controls, this deals with things like how we restrict admin access to our AWS accounts, which will probably be documented in the SSP.

### `s`: GSA Container Security Benchmark

This section contains all of our GSA specific controls around Docker and containerization. 

### `sa-`: System and Services Acquisition

This family deals with how we document and monitoring the state of the system. Any information about static analysis and regular system testing will go here.

### `sc-`: System and Communications Protection

This family deals with a lot of hardware controls we can probably inherit from AWS. It also deals with network configuration though, which we will have to document. Things like DDoS protection, minimizing network access between hosts, and hardware separation are documented here. 

### `si-`: System and Information Integrity

This family will contain things like any software scanning for security issues and necessary patches. It also deals with how we handle errors and sanitize user inputs. 

### `sr-`: Supply Chain Risk Management

This family potentially has the most entangled set of controls with other systems in our boundary and will take communication with security and compliance partners to help understand how changes to this system impact SCRM. The controls here range from setting up a SCRM team to how we scan our software to mitigate risk.

# Demos

Some [asciinema](https://asciinema.org/) demos are provided under [demos/](./demos/). To play back these terminal sessions, please `brew install asciinema` if you have not already. You can run these demos locally by doing, for instance, `asciinema play demos/trestle-add-control.cast`. (If you wish to record a demo, `asciinema rec <file>`; control-d exits the recording.)
