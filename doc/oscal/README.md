# Suggested OSCAL workflow

We currently have one [OSCAL profile](./profiles/nist-sp-800-53-rev5-moderate/profile.json) that adheres to a few NIST controls.

Here is a suggested compliance documentation workflow that uses [compliance-trestle](https://github.com/IBM/compliance-trestle):

- Add a control (say, `ac-8`) to the [profile](./profiles/nist-sp-800-53-rev5-moderate/profile.json).
  - Currently we only support NIST 800 53 controls.
  - ([CIS](https://www.cisecurity.org/controls/) support is forthcoming.)
- Run `make generate` to have `trestle` generate the corresponding control statement in Markdown.
  - Ideally this step would be automated via a CI pipeline.
- Fill out the implementation detail stubs for that control.
  - It is OK to leave them blank initially if we are unsure.
  - We will backfill missing implementation descriptions as we go along.
  - If we need to link to existing code, please link to high level artifacts with a general description.
    - Please avoid linking directly to lines of code as these will change over time.
  - For example, please link to the `identity-gitlab` cookbook instead of line 8 of `http-proxy.conf.erb`.
- Run `make assemble` to have `trestle` generate the "system security plan" (a bit of a misnomer but it is an hard-coded `trestle` workflow).
  - The resulting [SSP](./system-security-plans/nist-sp-800-53-rev5-moderate/system-security-plan.json) is an OSCAL documentation with our compliance implementation notes.

## Notes

- We are using JSON primarily because `trestle` YAML support is spotty. We hope this changes in the future.
- We do not need a lot of features that `trestle` currently offers and we intend to use a small subset of `trestle` features to get us used to a compliance documentation workflow and we will only expand upon this workflow when we have to.
  - This workflow is intentionally primitive: we generate only the control documentation and fill out the implementation details.
  - We do not support profile authoring or editing or adding items in the control statement.
  - This also means that we do not (currently) have plans to actually use the SSP OSCAL file but the SSP is nonetheless is intended to be a final compliance artifact.
- We also plan to automate link checking and validation via CI pipelines.

# Research summary

As of November 2021, we are exploring the use of [OSCAL](https://pages.nist.gov/OSCAL/) (Open Security Controls Assessment Language) as a way to automate controls documentation and thereby make the compliance process easier for everyone involved.

Upon talking with other parts of TTS, we found out cloud.gov once [attempted to automate FedRAMP assessments](https://gcn.com/articles/2021/11/03/psi-fedramp-oscal.aspx), and if successful, would have been the first organization to generate a SSP (system security plan) from OSCAL and machine-readable documents. However, this effort seems to have fallen by the wayside due to administrative turnover. As far as we can determine, no one else in TTS is doing compliance-as-code successfully, but of course this will not prevent us from trying.

We have yet to find a working and extant OSCAL-generated SSP, if any indeed exists. That being said, NIST offers some samples of [how a SSP could be structured in OSCAL](https://github.com/usnistgov/oscal-content/blob/master/examples/ssp/yaml/ssp-example.yaml).

## Recommendations

This document outlines some possible workflows and tools we could use, but our recommended process is to start with piecemeal OSCAL yaml files and eventually add in or build scaffolding (such as [SSP generators](https://github.com/GSA/oscal-ssp-to-word) and, much later, signing and auditing tools) as we learn more about our needs and iterate on our compliance processes.

# Tools

# compliance-trestle

Perhaps the most comprehensive tool for OSCAL authoring is IBM's [compliance-trestle](https://github.com/IBM/compliance-trestle) project, which is designed to operate as a CI/CD pipeline for processing compliance artifacts. Notably, `compliance-trestle` offers support for authoring Markdown for documentary artifacts and (some preliminary) [diagrams.net](diagrams.net) support for architecture diagrams. Caveat is that this project is still in beta and rather [opinionated](https://ibm.github.io/compliance-trestle/cli/#opinionated-directory-structure).

James' commentary:

> I believe `compliance-trestle` seems too heavy-weight for our needs right now, but it could be that we eventually evolve our OSCAL documenting process to something that would require the full power of `compliance-trestle`. I am also unsure of the benefit of using Markdown (in lieu of straight-up OSCAL yaml) and suggest avoiding that particular approach until we need it.

# GovReady-Q

[GovReady-Q](https://github.com/GovReady/govready-q) is web based self-service GRC tool to automate security assessments and compliance. Some support for importing and exporting OSCAL data models. This project is also in beta.

James' commentary:

> Looks like a thin wrapper around a commercial service (GovReady). There are some interesting approaches to compliance application and authoring tools but I think this is fundamentally the wrong direction to take for this project: I would prefer not to have a separate web service but rather bake in compliance assessment into our processes from the start.

# oscalkit

[oscalkit](https://github.com/GoComply/oscalkit) is a toolkit to convert, validate, and sign OSCAL artifacts.

James' commentary:

> Again a project that is backed by a commercial company (GoComply). This project still relies on older (obsolete) OSCAL standard definitions and thus is not quite completely up to date. Nonetheless, it is one of the few open source tools that provides basic validation of OSCAL documents (unfortunately only against JSON or XML schemas).

# Miscellany

- [Risk Redux](https://github.com/risk-redux/control_freak): display NIST 800-53 control catalogs in a [searchable format](https://controlfreak5.risk-redux.io/) (try searching for, e.g., "remote access").

- [Awesome OSCAL](https://github.com/oscal-club/awesome-oscal): a community-curated collection of OSCAL tools (in their own words, "maybe not quite production ready").

- [OSCAL Workshop (2021)](https://www.nist.gov/news-events/events/2021/02/2nd-open-security-controls-assessment-language-oscal-workshop): Hosts videos of the second OSCAL workshop.
