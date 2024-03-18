---

# Architecture Decision Record 12: On-Call Notifications with AWS Incident Manager

> We will use AWS Incident Manager for on-call notifications.

__Status__: Proposed

## Context

Splunk On-Call has ceased pursuing FedRAMP Moderate assessment, and so their
conditional ATO will expire on 2 April 2024. By then, Login.gov needs to
transition to another paging solution.

The leading candidates for a replacement are:

### AWS Incident Manager

A feature of our existing AWS System Manager service, this doesn't require an
acquisition, but doesn't have a mobile app, and our engineers haven't used or
integrated it.

[User guide](https://docs.aws.amazon.com/incident-manager/latest/userguide/what-is-incident-manager.html)

### PagerDuty

PagerDuty offers a user experience closer to Splunk. FedRAMP lists its
compliance status as "in process"[^1].

[^1]: https://marketplace.fedramp.gov/products/FR2310974411

## Decision

We will implement AWS Incident Manager for our paging solution. It is a NON-GOAL
to handle other aspects of incident management, e.g. incident tracking, review,
etc with AWS IM.

## Consequences

Some workflows will be impacted due to Incident Manager's lack of a mobile app. Examples:

* Repeated notifications in case a responder misses the initial page are limited
  to ~6 per escalation stage.
* When a page is received, there is no capability to page an additional team
  from a mobile device.

Our alerting architecture changes: instead of NewRelic sending alerts to Splunk,
we will configure a SaaS partner integration with New Relic as the Partner Event
Source. This will enable New Relic to publish events to a dedicated EventBridge
event bus within the Prod account; no other integrations or events will be
publishing to this event bus. A Rule configuration will be created within
EventBridge to send all events received on the event bus to a Response Plan
configured in the AWS Incident Manager service. A custom IAM role with the least
permissions required to operate the integration successfully will be created to
enable EventBridge to invoke the target of the rule (Incident Manager). Security
will enable monitoring for this IAM role to ensure only the expected services
are invoked by the EventBridge Rule.

## Alternatives Considered

### Splunk On-Call

Splunk is no longer pursuing a FedRAMP Moderate assessment, which was a condition of their ATO.

### PagerDuty

PagerDuty's FedRAMP status is "in process".

### GitLab

While we already run a GitLab instance in our ATO, its notification capabilities
have limitations compared to the other alternatives:

* GitLab only sends one email (that may need to be to a email-to-SMS gateway) to a responder per escalation level.
* GitLab can not send voice notifications.
* GitLab runs on one instance in us-west-2, and experiences regular downtime as we upgrade it.
