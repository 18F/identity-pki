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
