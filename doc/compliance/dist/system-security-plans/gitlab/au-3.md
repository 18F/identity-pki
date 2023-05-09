---
status:
  - c-implemented
  - c-documented
  - c-in-parent-ssp

---

# au-3 - \[catalog\] Content of Audit Records

## Control Statement

The information system generates audit records containing information that establishes what type of event occurred, when the event occurred, where the event occurred, the source of the event, the outcome of the event, and the identity of any individuals or subjects associated with the event.

## Control Objective

Determine if the information system generates audit records containing information that establishes:

- \[1\] what type of event occurred;

- \[2\] when the event occurred;

- \[3\] where the event occurred;

- \[4\] the source of the event;

- \[5\] the outcome of the event; and

- \[6\] the identity of any individuals or subjects associated with the event.

## Control guidance

Audit record content that may be necessary to satisfy the requirement of this control, includes, for example, time stamps, source and destination addresses, user/process identifiers, event descriptions, success/fail indications, filenames involved, and access control or flow control rules invoked. Event outcomes can include indicators of event success or failure and event-specific results (e.g., the security state of the information system after the event occurred).

______________________________________________________________________

## What is the solution and how is it implemented?

The GitLab component aligns with AU-3 from the main Login.gov SSP.

______________________________________________________________________
