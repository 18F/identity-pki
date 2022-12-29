resource "aws_ssm_document" "config_access_key_rotation_ssm_doc" {
  name            = "${var.config_access_key_rotation_name}-automation-doc"
  document_format = "YAML"
  document_type   = "Automation"

  content = <<DOC
    schemaVersion: "0.3"
    description: Automation Document For resolving a User from a ResourceId
    assumeRole: "{{ AutomationAssumeRole }}"
    parameters:
      ResourceId:
        type: String
        description: (Required) The ResourceId of a User
      AutomationAssumeRole:
        type: String
        description: >-
          (Optional) The ARN of the role that allows Automation to perform
          the actions on your behalf.
    mainSteps:
      - name: resolveUsername
        action: "aws:executeAwsApi"
        inputs:
          Service: config
          Api: ListDiscoveredResources
          resourceType: "AWS::IAM::User"
          resourceIds:
            - "{{ResourceId}}"
        outputs:
          - Name: configUserName
            Selector: "$.resourceIdentifiers[0].resourceName"
            Type: String
      - name: publishMessage
        action: "aws:executeAutomation"
        maxAttempts: 1
        timeoutSeconds: 30
        onFailure: Abort
        inputs:
          DocumentName: AWS-PublishSNSNotification
          RuntimeParameters:
            TopicArn: "arn:aws:sns:${var.region}:${data.aws_caller_identity.current.account_id}:${var.slack_events_sns_topic}"
            Message: {"Account": "{{global:ACCOUNT_ID}}", "User": "{{resolveUsername.configUserName}}", "Reason": "needs to rotate their Access Key. Active access keys should be rotated within 90 days to be marked as Compliant to AWS Config Rules. Rotate access key to avoid it from being Deleted or marked as Inactive. Runbook: https://github.com/18F/identity-devops/wiki/Setting-Up-AWS-Vault#rotating-aws-keys"}
    outputs:
      - resolveUsername.configUserName
DOC
}
