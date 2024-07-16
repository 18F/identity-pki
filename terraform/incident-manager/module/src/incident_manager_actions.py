import json
import os
import logging
import boto3
from datetime import datetime


logger = logging.getLogger()
logger.setLevel(logging.INFO)
incident_manager = boto3.client("ssm-incidents")
contacts_manager = boto3.client("ssm-contacts")


def lambda_handler(event, context):
    logger.info(event)

    if event["source"] == "aws.cloudwatch":
        match event["alarmData"]["state"]["value"]:
            case "ALARM":
                logger.info("ALARM")
                open_incident(
                    response_plan_arn=os.environ["RESPONSE_PLAN_ARN"],
                    title=f"{os.environ['RESPONSE_PLAN_TEAM']} Response Plan [{event['alarmData']['alarmName']}]",
                    raw_data=json.dumps(event),
                    source=f"lambda.{event['source']}",
                    timestamp=event["time"],
                    arn="",
                    description=event.get("configuration", {}).get("description", ""),
                    reason=event.get("alarmData", {})
                    .get("state", {})
                    .get("reason", ""),
                    data=event.get("alarmData", {})
                    .get("state", {})
                    .get("reasonData", ""),
                )
            case "OK":
                logger.info("OK")
                close_incident(
                    title=f"Platform Response Plan [{event['alarmData']['alarmName']}]",
                )

            case _:
                logger.info("Unknown alarm status")

    else:
        open_incident(
            response_plan_arn=os.environ["RESPONSE_PLAN_ARN"],
            title=f"{os.environ['RESPONSE_PLAN_TEAM']} Response Plan [{event['detail']['alarmName']}]",
            raw_data=json.dumps(event),
            source=f"lambda.{event['source']}",
            timestamp=event["time"],
            arn="",
            description="",
            reason=event["detail"]["state"]["reason"],
            data=event["detail"]["state"]["reasonData"],
        )


def list_open_incidents(title):
    incidents = incident_manager.list_incident_records(
        filters=[
            {
                "condition": {
                    "equals": {
                        "stringValues": [
                            "OPEN",
                        ]
                    }
                },
                "key": "status",
            },
        ],
        maxResults=100,
    )

    return [
        incident
        for incident in incidents["incidentRecordSummaries"]
        if incident["title"] in [title]
    ]


def list_open_engagements(arn):
    incident_engagements = contacts_manager.list_engagements(
        MaxResults=123,
        IncidentId=arn,
    )
    return [
        engagement["EngagementArn"]
        for engagement in incident_engagements["Engagements"]
    ]


def open_incident(
    response_plan_arn="",
    title="",
    raw_data="",
    source="",
    arn="",
    description="",
    reason="",
    timestamp="",
    data={},
):

    incidents = list_open_incidents(title)

    if len(incidents) > 0:
        add_alarm_as_timeline_event(incidents[0]["arn"], timestamp)
    else:
        incident = incident_manager.start_incident(
            impact=2,
            responsePlanArn=response_plan_arn,
            title=title,
            triggerDetails={
                "rawData": raw_data,
                "source": source[:50],
                "timestamp": timestamp,
            },
        )

        update_incident_summary(
            incident["incidentRecordArn"],
            summary_template(
                arn=arn,
                description=description,
                reason=reason,
                timestamp=timestamp,
                data=data,
            ),
        )


def close_incident(title=""):
    for incident in list_open_incidents(title):
        for engagement in list_open_engagements(incident["arn"]):
            contacts_manager.stop_engagement(
                EngagementId=engagement, Reason="Incident resolved"
            )
        incident_manager.update_incident_record(arn=incident["arn"], status="RESOLVED")


def summary_template(arn="", description="", reason="", timestamp="", data={}):
    return f"""
# Alarm summary

***
**Alarm ARN:** {arn}
**Alarm description:** {description}

**Reason:** {reason}


**Timestamp:**  {timestamp}

**Data:**
```
{json.dumps(data, indent=2)}
```
  """


def update_incident_summary(incident_arn, summary_template):
    incident_manager.update_incident_record(
        arn=incident_arn,
        summary=summary_template,
    )


def add_alarm_as_timeline_event(arn, timestamp):
    incident_manager.create_timeline_event(
        eventData='"Alarm triggered"',
        eventTime=timestamp,
        eventType="Custom Event",
        incidentRecordArn=arn,
    )
